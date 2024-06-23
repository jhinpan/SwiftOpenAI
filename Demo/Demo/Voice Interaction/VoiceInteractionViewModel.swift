import AVFoundation
import Speech
import SwiftUI
import SwiftOpenAI

class VoiceInteractionViewModel: NSObject, ObservableObject {
    @Published var recognizedText: String = ""
    @Published var responseText: String = ""
    @Published var isLoadingTextToSpeechAudio: TextToSpeechType = .noExecuted
    @Published var isListening: Bool = false
    
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
        // Ensure audio session is active and configured for recording
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
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
        } catch {
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
        
        // Deactivate the audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
    
    func processVoiceInput() {
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
                        }
                        await self.createSpeech(input: textResponse)
                    }
                }
            } catch {
                print("Error processing voice input: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    func createSpeech(input: String) async {
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
                    
                    print("Audio playback started")
                } catch {
                    print("Error initializing audio player: \(error.localizedDescription)")
                }
            } else {
                print("Error trying to save file in filePath")
            }
            
        } catch {
            print("Error creating Audios: \(error.localizedDescription)")
        }
    }
}

extension VoiceInteractionViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isLoadingTextToSpeechAudio = .finishedPlaying
        print("Audio playback finished")
    }
}
