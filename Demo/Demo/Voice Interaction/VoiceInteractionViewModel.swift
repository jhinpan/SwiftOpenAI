import AVFoundation
import Speech
import SwiftUI
import SwiftOpenAI

class VoiceInteractionViewModel: NSObject, ObservableObject {
    @Published var recognizedText: String = ""
    @Published var responseText: String = ""
    @Published var isLoadingTextToSpeechAudio: TextToSpeechType = .noExecuted
    @Published var isListening: Bool = false
    @Published var log: [(String, String)] = []
    
    private let openAIClient = SwiftOpenAI(apiKey: Bundle.main.getOpenAIApiKey()!)
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioPlayer: AVAudioPlayer?
    
    var initialPrompt: String
    var modulesData: ModulesData?
    
    enum TextToSpeechType {
        case noExecuted
        case isLoading
        case finishedLoading
        case finishedPlaying
    }
    
    override init() {
        self.modulesData = loadModulesData()
        self.initialPrompt = VoiceInteractionViewModel.createInitialPrompt(with: self.modulesData)
        super.init()
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                print("Microphone permission not granted")
            }
        }
        
        self.log.append((UUID().uuidString, self.initialPrompt))  // Log the initial prompt with a unique ID
    }
    
    static func createInitialPrompt(with modulesData: ModulesData?) -> String {
        var prompt = """
        You are A11ybits Manager, an assistant knowledgeable about all sensing modules and feedback modules. You can provide detailed information on various modules and how to use them. You also have access to a JSON file that contains data about these modules.
        """
        if let modulesData = modulesData {
            let sensingModules = modulesData.sensingModules.map { "\($0.name): \($0.description)" }.joined(separator: ", ")
            let feedbackModules = modulesData.feedbackModules.map { "\($0.name): \($0.description)" }.joined(separator: ", ")
            prompt += "\nSensing Modules: \(sensingModules)"
            prompt += "\nFeedback Modules: \(feedbackModules)"
        }
        return prompt
    }
    
    func startRecording() {
        log.append((UUID().uuidString, "Starting recording..."))
        
        // Ensure audio session is active and configured for recording
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            log.append((UUID().uuidString, "Failed to set up audio session: \(error.localizedDescription)"))
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
            log.append((UUID().uuidString, "Audio engine started"))
        } catch {
            log.append((UUID().uuidString, "Failed to start audio engine: \(error.localizedDescription)"))
            print("Failed to start audio engine: \(error.localizedDescription)")
            return
        }
        
        DispatchQueue.main.async {
            self.isListening = true
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                    print("Recognized text: \(self.recognizedText)")  // Debugging statement
                    self.log.append((UUID().uuidString, "Partial recognized text: \(self.recognizedText)")) // Log partial results
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.stopRecording()
                self.log.append((UUID().uuidString, "Final recognized text: \(self.recognizedText)"))
                self.processVoiceInput()
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
        
        log.append((UUID().uuidString, "Stopped recording"))
        
        // Deactivate the audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            log.append((UUID().uuidString, "Failed to deactivate audio session: \(error.localizedDescription)"))
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
    
    func processVoiceInput() {
        log.append((UUID().uuidString, "Processing voice input..."))
        
        Task {
            do {
                if let response = try await openAIClient.createChatCompletions(
                    model: .gpt4o(.base),
                    messages: [.init(text: initialPrompt, role: .system), .init(text: recognizedText, role: .user)],
                    optionalParameters: .init(temperature: 0.5)
                ) {
                    if let textResponse = response.choices.first?.message.content {
                        DispatchQueue.main.async {
                            self.responseText = textResponse
                            self.log.append((UUID().uuidString, "GPT-4o response: \(self.responseText)"))
                        }
                        await self.createSpeech(input: textResponse)
                    }
                }
            } catch {
                log.append((UUID().uuidString, "Error processing voice input: \(error.localizedDescription)"))
                print("Error processing voice input: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    func createSpeech(input: String) async {
        log.append((UUID().uuidString, "Creating speech..."))
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
                    log.append((UUID().uuidString, "File created: \(filePath)"))
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
                    log.append((UUID().uuidString, "Audio playback started"))
                } catch {
                    log.append((UUID().uuidString, "Error initializing audio player: \(error.localizedDescription)"))
                    print("Error initializing audio player: \(error.localizedDescription)")
                }
            } else {
                log.append((UUID().uuidString, "Error trying to save file in filePath"))
                print("Error trying to save file in filePath")
            }
            
        } catch {
            log.append((UUID().uuidString, "Error creating Audios: \(error.localizedDescription)"))
            print("Error creating Audios: \(error.localizedDescription)")
        }
    }
    
    func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
}

extension VoiceInteractionViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isLoadingTextToSpeechAudio = .finishedPlaying
        log.append((UUID().uuidString, "Audio playback finished"))
        print("Audio playback finished")
    }
}

struct Module: Codable {
    let id: String
    let name: String
    let description: String
}

struct ModulesData: Codable {
    let sensingModules: [Module]
    let feedbackModules: [Module]
}

func loadModulesData() -> ModulesData? {
    guard let url = Bundle.main.url(forResource: "modules", withExtension: "json") else {
        print("JSON file not found")
        return nil
    }
    
    do {
        let data = try Data(contentsOf: url)
        let modulesData = try JSONDecoder().decode(ModulesData.self, from: data)
        print("Modules data loaded successfully")  // Debugging statement
        return modulesData
    } catch {
        print("Error loading JSON data: \(error)")
        return nil
    }
}
