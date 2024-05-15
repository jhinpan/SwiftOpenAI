import Foundation

protocol CreateTranslationRequestProtocol {
    func execute(api: API,
                 apiKey: String,
                 file: Data,
                 model: OpenAITranscriptionModelType,
                 prompt: String,
                 responseFormat: OpenAIAudioResponseType,
                 temperature: Double) async throws -> AsyncThrowingStream<CreateTranslationDataModel, Error>
}

final public class CreateTranslationRequest: NSObject, CreateTranslationRequestProtocol {
    public typealias Init = (_ api: API,
                             _ apiKey: String,
                             _ file: Data,
                             _ model: OpenAITranscriptionModelType,
                             _ prompt: String,
                             _ responseFormat: OpenAIAudioResponseType,
                             _ temperature: Double) async throws -> AsyncThrowingStream<CreateTranslationDataModel, Error>
    
    private var urlSession: URLSession?
    private var dataTask: URLSessionDataTask?
    private var continuation: AsyncThrowingStream<CreateTranslationDataModel, Error>.Continuation?
    
    public override init() {
        super.init()
    }
    
    public func execute(api: API,
                        apiKey: String,
                        file: Data,
                        model: OpenAITranscriptionModelType,
                        prompt: String,
                        responseFormat: OpenAIAudioResponseType,
                        temperature: Double) async throws -> AsyncThrowingStream<CreateTranslationDataModel, Error> {
        
        return AsyncThrowingStream<CreateTranslationDataModel, Error> { continuation in
            self.continuation = continuation
            
            var endpoint = OpenAIEndpoints.createTranslation(file: file, model: model, prompt: prompt, responseFormat: responseFormat, temperature: temperature).endpoint
            api.routeEndpoint(&endpoint, environment: OpenAIEnvironmentV1())
            
            let boundary = UUID().uuidString
            
            var urlRequest = api.buildURLRequest(endpoint: endpoint)
            api.addHeaders(urlRequest: &urlRequest,
                           headers: ["Content-Type": "multipart/form-data; boundary=\(boundary)",
                                     "Authorization": "Bearer \(apiKey)"])
            
            var body = Data()
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
            body.append("whisper-1\r\n".data(using: .utf8)!)
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"steve.mp4\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)
            body.append(file)
            body.append("\r\n".data(using: .utf8)!)
            
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            urlRequest.httpBody = body
            
            self.urlSession = URLSession(configuration: .default,
                                         delegate: self,
                                         delegateQueue: OperationQueue())
            
            dataTask = urlSession?.dataTask(with: urlRequest)
            dataTask?.resume()
        }
    }
}

extension CreateTranslationRequest: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        do {
            let createTranslationDataModel = try JSONDecoder().decode(CreateTranslationDataModel.self, from: data)
            self.continuation?.yield(createTranslationDataModel)
        } catch {
            print("Error al parsear JSON:", error.localizedDescription)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else {
            continuation?.finish()
            return
        }
        continuation?.finish(throwing: error)
    }
}
