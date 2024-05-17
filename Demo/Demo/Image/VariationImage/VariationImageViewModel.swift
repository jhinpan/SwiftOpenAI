import Foundation
import SwiftOpenAI

@Observable
class VariationImageViewModel {
    private let openAI = SwiftOpenAI(apiKey: Bundle.main.getOpenAIApiKey()!)
    var imageURL: URL?
    var isLoading: Bool = false
    
    @MainActor
    func variationImage(imageMask: Data) async {
        isLoading = true
        
        do {
            let variationImage = try await openAI.variationImage(model: .dalle(.dalle2), imageData: imageMask, numberOfImages: 1, size: .s512)
            
            await MainActor.run {
                guard let variationImage, let urlString = variationImage.data.map({ $0.url }).last else {
                    isLoading = false
                    return
                }
                imageURL =  URL(string: urlString)
                isLoading = false
            }
        } catch {
            isLoading = false
            print("Error creating variation image", error.localizedDescription)
        }
    }
}
