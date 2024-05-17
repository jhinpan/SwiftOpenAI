import Foundation

protocol EditImageRequestProtocol {
    func execute(api: API,
                 apiKey: String,
                 model: OpenAIImageModelType,
                 imageData: Data,
                 maskData: Data,
                 prompt: String,
                 numberOfImages: Int,
                 size: ImageSize) async throws -> CreateImageDataModel?
}

final public class EditImageRequest: NSObject, EditImageRequestProtocol {
    public typealias Init = (_ api: API,
                             _ apiKey: String,
                             _ model: OpenAIImageModelType,
                             _ imageData: Data,
                             _ maskData: Data,
                             _ prompt: String,
                             _ numberOfImages: Int,
                             _ size: ImageSize) async throws -> CreateImageDataModel?
    
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
                        size: ImageSize) async throws -> CreateImageDataModel? {
        
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
        
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let variationImageDataModel = try JSONDecoder().decode(CreateImageDataModel.self, from: data)
        
        return variationImageDataModel
    }
}
