import Foundation

struct VariationImageEndpoint: Endpoint {
    private let model: OpenAIImageModelType

    var method: HTTPMethod {
        .POST
    }

    var path: String = "images/variations"

    init(model: OpenAIImageModelType) {
        self.model = model
    }

    var parameters: [String: Any]? {
        ["model": self.model.name as Any]
    }
}
