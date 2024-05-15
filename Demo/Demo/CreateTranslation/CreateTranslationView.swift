import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct CreateTranslationView: View {
    @Binding var viewModel: CreateTranslationViewModel
    
    var body: some View {
        Form {
            Section("Select Video or Video/Audio") {
                VStack {
                    PhotosPicker(selection: $viewModel.photoSelection,
                                 matching: .videos,
                                 photoLibrary: .shared()) {
                        Label("Add video or audio",
                              systemImage: "video.fill")
                    }
                                 .frame(height: 300)
                                 .photosPickerStyle(.inline)
                                 .onChange(of: viewModel.photoSelection!) { oldValue, newValue in
                                     newValue.loadTransferable(type: Data.self) { [self] result in
                                         switch result {
                                         case .success(let data):
                                             if let data {
                                                 viewModel.currentData = data
                                             } else {
                                                 print("No supported content type found.")
                                             }
                                         case .failure(let error):
                                             fatalError(error.localizedDescription)
                                         }
                                     }
                                 }
                    Button {
                        Task {
                            await viewModel.createTranscription()
                        }
                    } label: {
                        Text("Translate Video/Audio")
                    }
                    .disabled(viewModel.currentData == nil)
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                }
            }
            
            Section("Translation") {
                if viewModel.isLoading {
                    TypingIndicatorView()
                } else {
                    if !viewModel.translation.isEmpty {
                        Text(viewModel.translation)
                            .font(.system(size: 22))
                            .italic()
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                }
            }
        }
    }
}

#Preview {
    CreateTranscriptView(viewModel: .constant(.init()))
}
