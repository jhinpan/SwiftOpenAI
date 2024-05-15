import Foundation

struct CreateTranslationEndpoint: Endpoint {
    private let file: Data
    private let model: OpenAITranscriptionModelType
    private let prompt: String
    private let responseFormat: OpenAIAudioResponseType
    private let temperature: Double
    
    var method: HTTPMethod {
        .POST
    }
    
    var path: String = "audio/translations"
    
    init(file: Data,
         model: OpenAITranscriptionModelType,
         prompt: String = "",
         responseFormat: OpenAIAudioResponseType,
         temperature: Double = 0.0) {
        self.file = file
        self.model = model
        self.prompt = prompt
        self.responseFormat = responseFormat
        self.temperature = temperature
    }
    
    var parameters: [String: Any]? {
        ["model": self.model.rawValue as Any,
         "prompt": self.prompt as Any,
         "response_format": self.responseFormat.rawValue as Any,
         "temperature": self.temperature as Any]
    }
}
