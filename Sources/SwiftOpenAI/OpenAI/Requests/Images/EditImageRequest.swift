import Foundation

protocol EditImageRequestProtocol {
    func execute(api: API,
                 apiKey: String,
                 model: OpenAIImageModelType,
                 imageData: Data,
                 maskData: Data,
                 prompt: String,
                 numberOfImages: Int,
                 size: ImageSize) async throws -> AsyncThrowingStream<CreateImageDataModel, Error>
}

final public class EditImageRequest: NSObject, EditImageRequestProtocol {
    public typealias Init = (_ api: API,
                             _ apiKey: String,
                             _ model: OpenAIImageModelType,
                             _ imageData: Data,
                             _ maskData: Data,
                             _ prompt: String,
                             _ numberOfImages: Int,
                             _ size: ImageSize) async throws -> AsyncThrowingStream<CreateImageDataModel, Error>
    
    private var urlSession: URLSession?
    private var dataTask: URLSessionDataTask?
    private var continuation: AsyncThrowingStream<CreateImageDataModel, Error>.Continuation?
    
    public override init() {
        super.init()
    }
    
    public func execute(api: API,
                        apiKey: String,
                        model: OpenAIImageModelType,
                        imageData: Data,
                        maskData: Data,
                        prompt: String,
                        numberOfImages: Int,
                        size: ImageSize) async throws -> AsyncThrowingStream<CreateImageDataModel, Error> {
        return AsyncThrowingStream<CreateImageDataModel, Error> { continuation in
            self.continuation = continuation

            var endpoint = OpenAIEndpoints.editImage(model: model).endpoint
            api.routeEndpoint(&endpoint, environment: OpenAIEnvironmentV1())
            
            let boundary = "Boundary-\(UUID().uuidString)"
                        
            var urlRequest = api.buildURLRequest(endpoint: endpoint)
            api.addHeaders(urlRequest: &urlRequest,
                           headers: ["Content-Type": "multipart/form-data; boundary=\(boundary)",
                                     "Authorization": "Bearer \(apiKey)"])
            
            let formData = MultipartFormData(boundary: boundary)

            formData.appendField(name: "prompt", value: prompt)
            formData.appendField(name: "n", value: String(numberOfImages))
            formData.appendField(name: "size", value: size.rawValue)
            formData.appendImageData(fieldName: "image", data: imageData, filename: "image.png", mimeType: "image/png")
            formData.appendImageData(fieldName: "mask", data: maskData, filename: "mask.png", mimeType: "image/png")
            formData.finalizeBody()
            
            urlRequest.httpBody = formData.getHttpBody()
            
            self.urlSession = URLSession(configuration: .default,
                                         delegate: self,
                                         delegateQueue: OperationQueue())
            dataTask = urlSession?.dataTask(with: urlRequest)
            dataTask?.resume()
        }
    }
}

extension EditImageRequest: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        do {
            let editImageDataModel = try JSONDecoder().decode(CreateImageDataModel.self, from: data)
            self.continuation?.yield(editImageDataModel)
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
