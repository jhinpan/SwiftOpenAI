import AVFoundation
import Speech
import SwiftUI
import SwiftOpenAI

class VoiceInteractionViewModel: NSObject, ObservableObject {
    @Published var recognizedText: String = ""
    @Published var responseText: String = ""
    @Published var isLoadingTextToSpeechAudio: TextToSpeechType = .noExecuted
    @Published var isListening: Bool = false
    @Published var log: [String] = []
    
    private let openAIClient = SwiftOpenAI(apiKey: Bundle.main.getOpenAIApiKey()!)
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioPlayer: AVAudioPlayer?
    
    enum TextToSpeechType {
        case noExecuted
        case isLoading
        case finishedLoading
        case finishedPlaying
    }
    
    override init() {
        super.init()
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                print("Microphone permission not granted")
            }
        }
    }
    
    func startRecording() {
        log.append("Starting recording...")
        
        // Ensure audio session is active and configured for recording
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            log.append("Failed to set up audio session: \(error.localizedDescription)")
            print("Failed to set up audio session: \(error.localizedDescription)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        
        // Remove existing tap before adding a new one
        inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.shouldReportPartialResults = true
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            log.append("Audio engine started")
        } catch {
            log.append("Failed to start audio engine: \(error.localizedDescription)")
            print("Failed to start audio engine: \(error.localizedDescription)")
            return
        }
        
        DispatchQueue.main.async {
            self.isListening = true
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self.recognizedText = result.bestTranscription.formattedString
                    self.log.append("Recognized text: \(self.recognizedText)")
                }
                
                if error != nil || result?.isFinal == true {
                    self.stopRecording()
                    self.processVoiceInput()
                }
            }
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        DispatchQueue.main.async {
            self.isListening = false
        }
        
        log.append("Stopped recording")
        
        // Deactivate the audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            log.append("Failed to deactivate audio session: \(error.localizedDescription)")
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
    
    func processVoiceInput() {
        log.append("Processing voice input...")
        
        Task {
            do {
                if let response = try await openAIClient.createChatCompletions(
                    model: .gpt4o(.base),
                    messages: [.init(text: recognizedText, role: .user)],
                    optionalParameters: .init(temperature: 0.5)
                ) {
                    if let textResponse = response.choices.first?.message.content {
                        DispatchQueue.main.async {
                            self.responseText = textResponse
                            self.log.append("GPT-4o response: \(self.responseText)")
                        }
                        await self.createSpeech(input: textResponse)
                    }
                }
            } catch {
                log.append("Error processing voice input: \(error.localizedDescription)")
                print("Error processing voice input: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    func createSpeech(input: String) async {
        log.append("Creating speech...")
        isLoadingTextToSpeechAudio = .isLoading
        
        do {
            let data = try await openAIClient.createSpeech(model: .tts(.tts1),
                                                           input: input,
                                                           voice: .alloy,
                                                           responseFormat: .mp3,
                                                           speed: 1.0)
            
            if let filePath = FileManager.default.urls(for: .documentDirectory,
                                                       in: .userDomainMask).first?.appendingPathComponent("speech.mp3"),
               let data {
                do {
                    try data.write(to: filePath)
                    log.append("File created: \(filePath)")
                    print("File created: \(filePath)")
                    
                    // Configure audio session for playback
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(.playback, mode: .default)
                    try audioSession.setActive(true)
                    
                    audioPlayer = try AVAudioPlayer(contentsOf: filePath)
                    audioPlayer?.delegate = self
                    audioPlayer?.prepareToPlay()
                    audioPlayer?.play()
                    isLoadingTextToSpeechAudio = .finishedLoading
                    log.append("Audio playback started")
                } catch {
                    log.append("Error initializing audio player: \(error.localizedDescription)")
                    print("Error initializing audio player: \(error.localizedDescription)")
                }
            } else {
                log.append("Error trying to save file in filePath")
                print("Error trying to save file in filePath")
            }
            
        } catch {
            log.append("Error creating Audios: \(error.localizedDescription)")
            print("Error creating Audios: \(error.localizedDescription)")
        }
    }
}

extension VoiceInteractionViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isLoadingTextToSpeechAudio = .finishedPlaying
        log.append("Audio playback finished")
        print("Audio playback finished")
    }
}
