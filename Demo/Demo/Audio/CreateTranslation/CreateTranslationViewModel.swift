import Foundation
import SwiftUI
import PhotosUI
import SwiftOpenAI

@Observable
class CreateTranslationViewModel {
    var openAI = SwiftOpenAI(apiKey: Bundle.main.getOpenAIApiKey()!)
    
    var photoSelection: PhotosPickerItem? = .init(itemIdentifier: "")
    var translation: String = ""
    var isLoading: Bool = false
    
    var currentData: Data?
    
    func createTranscription() async {
        guard let data = currentData else {
            print("Error: Data is empty")
            return
        }
        
        isLoading = true
        let model: OpenAITranscriptionModelType = .whisper
        
        do {
            for try await newMessage in try await openAI.createTranslation(model: model,
                                                                           file: data,
                                                                           prompt: "",
                                                                           responseFormat: .mp3,
                                                                           temperature: 1.0) {
                print("Received Translation \(newMessage)")
                await MainActor.run {
                    isLoading = false
                    translation = newMessage.text
                }
            }
        } catch {
            print("Error creating Transcription from file: ", error.localizedDescription)
        }
    }
}
