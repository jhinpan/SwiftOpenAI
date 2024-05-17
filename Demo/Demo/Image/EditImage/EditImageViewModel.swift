import Foundation
import SwiftOpenAI

@Observable
class EditImageViewModel {
    private let openAI = SwiftOpenAI(apiKey: Bundle.main.getOpenAIApiKey()!)
    var imageURL: URL?
    var isLoading: Bool = false
    
    @MainActor
    func editImage(prompt: String, imageMask: Data, maskData: Data) async {
        isLoading = true
        
        do {
            let editedImage = try await openAI.editImage(model: .dalle(.dalle2), imageData: imageMask, maskData: maskData, prompt: prompt, numberOfImages: 1, size: .s512)
            await MainActor.run {
                guard let editedImage, let urlString = editedImage.data.map({ $0.url }).last else {
                    isLoading = false
                    return
                }
                imageURL =  URL(string: urlString)
                isLoading = false
            }
        } catch {
            isLoading = false
            print("Error creating edit image", error.localizedDescription)
        }
    }
}
