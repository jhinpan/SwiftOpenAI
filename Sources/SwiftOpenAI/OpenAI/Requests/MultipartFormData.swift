import Foundation

final public class MultipartFormData {
    private var body: Data = Data()
    private let boundary: String

    public init(boundary: String) {
        self.boundary = boundary
    }

    public func appendField(name: String, value: String, filename: String? = nil, mimeType: String? = nil) {
        var disposition = "Content-Disposition: form-data; name=\"\(name)\""
        if let filename = filename {
            disposition += "; filename=\"\(filename)\""
        }

        append("--\(boundary)\r\n")
        append("\(disposition)\r\n")

        if let mimeType = mimeType {
            append("Content-Type: \(mimeType)\r\n\r\n")
        } else {
            append("\r\n")
        }

        append(value)
        append("\r\n")
    }

    public func appendImageData(fieldName: String, data: Data, filename: String, mimeType: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        append("\r\n")
    }

    public func finalizeBody() {
        append("--\(boundary)--\r\n")
    }

    public func getHttpBody() -> Data {
        return body
    }

    private func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            body.append(data)
        }
    }
}
