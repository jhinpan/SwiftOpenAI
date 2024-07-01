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
    @Published var connections: [Connection] = []
    
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
        You are A11ybits Manager, an assistant knowledgeable about all sensing modules and feedback modules. You can provide detailed information on various modules and how to use them. You also have access to a JSON file that contains data about these modules. For those sensing & feedback modules, you should only offer information in the JSON file but not offer any other information that you learn. Besides that, we also want you to hide the specific JSON file towards users during interaction.
        
        You should recognize commands to connect among those sensing modules, feedback modules, phone-end modules and set parameters toward those specific modules. For example:
        - "Connect Temperature sensor with Speaker."
        - "I want to connect the Motion sensor with the vibration feedback module."
        - "Build connection between Light sensor and LEDMatrix."
        - "Set temperature to 75 degrees."
        
        Debugging Tips:
        - If you encounter any issues, please describe the problem in detail.
        - Make sure to check that the JSON file is correctly formatted and all required fields are present.
        - If the microphone is not working, ensure it has the necessary permissions.
        """
        if let modulesData = modulesData {
            let sensingModules = modulesData.sensingModules.map { "\($0.name): \($0.description), Data Format: \($0.dataFormat), Parameter Setting: \($0.parameterSetting)" }.joined(separator: ", ")
            let feedbackModules = modulesData.feedbackModules.map { "\($0.name): \($0.description), Data Format: \($0.dataFormat), Parameter Setting: \($0.parameterSetting)" }.joined(separator: ", ")
            let phoneEndModules = modulesData.phoneEndModules.map { "\($0.name): \($0.description), Data Format: \($0.dataFormat), Parameter Setting: \($0.parameterSetting)" }.joined(separator: ", ")
            prompt += "\nSensing Modules: \(sensingModules)"
            prompt += "\nFeedback Modules: \(feedbackModules)"
            prompt += "\nPhone End Modules: \(phoneEndModules)"
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
                            self.handleVoiceCommand(text: self.responseText)
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
    
    func handleVoiceCommand(text: String) {
        // Parse the text to identify commands for connecting modules and setting parameters
        if text.lowercased().contains("connect") || text.lowercased().contains("build connection") {
            // Extract module names
            let components = text.split(separator: " ")
            let sensingModulesNames = modulesData?.sensingModules.map { $0.name.lowercased() } ?? []
            let feedbackModulesNames = modulesData?.feedbackModules.map { $0.name.lowercased() } ?? []
            
            let sensingModuleName = components.first(where: { sensingModulesNames.contains($0.lowercased()) })
            let feedbackModuleName = components.first(where: { feedbackModulesNames.contains($0.lowercased()) })
            
            if let sensingModuleName = sensingModuleName, let feedbackModuleName = feedbackModuleName,
               let sensingModule = modulesData?.sensingModules.first(where: { $0.name.lowercased() == sensingModuleName.lowercased() }),
               let feedbackModule = modulesData?.feedbackModules.first(where: { $0.name.lowercased() == feedbackModuleName.lowercased() }) {
                
                var connection = Connection(sensingModule: sensingModule, feedbackModule: feedbackModule, parameter: "", threshold: "")
                connections.append(connection)
                log.append((UUID().uuidString, "Connected \(sensingModule.name) to \(feedbackModule.name)"))
                provideAudioFeedback(message: "Connected \(sensingModule.name) to \(feedbackModule.name)")
            } else {
                log.append((UUID().uuidString, "Failed to connect modules: modules not found"))
                provideAudioFeedback(message: "Failed to connect modules: modules not found")
            }
        } else if text.lowercased().contains("set") {
            // Extract module name, parameter, and value
            let components = text.split(separator: " ")
            let moduleName = components.first(where: { name in
                modulesData?.sensingModules.contains(where: { $0.name.lowercased() == name.lowercased() }) ?? false ||
                modulesData?.feedbackModules.contains(where: { $0.name.lowercased() == name.lowercased() }) ?? false
            })
            let parameter = components.first(where: { $0.lowercased() == "temperature" }) ?? ""
            let value = components.last ?? ""
            
            if let moduleName = moduleName,
               let index = connections.firstIndex(where: { $0.sensingModule.name.lowercased() == moduleName.lowercased() || $0.feedbackModule.name.lowercased() == moduleName.lowercased() }) {
                connections[index].parameter = String(parameter)
                connections[index].threshold = String(value)
                log.append((UUID().uuidString, "Set \(parameter) to \(value) for module \(moduleName)"))
                provideAudioFeedback(message: "Set \(parameter) to \(value) for module \(moduleName)")
            } else {
                log.append((UUID().uuidString, "Failed to set parameter: connection not found"))
                provideAudioFeedback(message: "Failed to set parameter: connection not found")
            }
        }
        
        // Print all connections for debugging purposes
        printConnections()
    }
    
    func provideAudioFeedback(message: String) {
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    func printConnections() {
        log.append((UUID().uuidString, "Current connections:"))
        for connection in connections {
            log.append((UUID().uuidString, "Sensing Module: \(connection.sensingModule.name), Feedback Module: \(connection.feedbackModule.name), Parameter: \(connection.parameter), Threshold: \(connection.threshold)"))
            print("Sensing Module: \(connection.sensingModule.name), Feedback Module: \(connection.feedbackModule.name), Parameter: \(connection.parameter), Threshold: \(connection.threshold)")
        }
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
    let name: String
    let dataFormat: String
    let parameterSetting: String
    let description: String
}

struct Connection: Codable {
    let sensingModule: Module
    let feedbackModule: Module
    var parameter: String
    var threshold: String // Changed to String for simplicity
}

struct ModulesData: Codable {
    let sensingModules: [Module]
    let feedbackModules: [Module]
    let phoneEndModules: [Module]
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
