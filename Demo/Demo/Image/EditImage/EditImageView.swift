import SwiftUI

struct EditImageView: View {
    var viewModel = EditImageViewModel()
    @State var text = ""
    @State var selectedImage: Image?
    @State var emptyImage: Image = Image(systemName: "photo.on.rectangle.angled")
    @State var showCamera: Bool = false
    @State var showGallery: Bool = false
    @State var lines: [Line] = []
    @FocusState var isFocused: Bool
    
    var currentImage: some View {
        if let selectedImage {
            return selectedImage
                .resizable()
                .scaledToFill()
                .frame(width: 300, height: 300)
        } else {
            return emptyImage
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
        }
    }
    
    var body: some View {
        Form {
            Text("Create a mask")
                .font(.headline)
                .padding(.vertical, 12)
            
            AsyncImage(url: viewModel.imageURL) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                VStack {
                    if !viewModel.isLoading {
                        ZStack {
                            currentImage
                            SwiftBetaCanvas(lines: $lines, currentLineWidth: 30)
                        }
                    } else {
                        HStack {
                            Spacer()
                            VStack {
                                ProgressView()
                                    .padding(.bottom, 12)
                                Text("Your image is being generated, please wait 5 seconds! 🚀")
                                    .multilineTextAlignment(.center)
                            }
                            Spacer()
                        }
                        
                    }
                }
                .frame(width: 300, height: 300)
            }
            
            HStack {
                Button {
                    showCamera.toggle()
                } label: {
                    Text("📷 Take a photo!")
                }
                .tint(.orange)
                .buttonStyle(.borderedProminent)
                .fullScreenCover(isPresented: $showCamera) {
                    CameraView(selectedImage: $selectedImage)
                }
                .padding(.vertical, 12)
                
                Spacer()
                
                Button {
                    showGallery.toggle()
                } label: {
                    Text("Open Gallery")
                }
                .tint(.purple)
                .buttonStyle(.borderedProminent)
                .fullScreenCover(isPresented: $showGallery) {
                    GalleryView(selectedImage: $selectedImage)
                }
                .padding(.vertical, 12)
            }
            
            TextField("Add a text and the AI will edit the image",
                      text: $text,
                      axis: .vertical)
            .lineLimit(10)
            .lineSpacing(5)
            
            HStack {
                Spacer()
                Button("🪄 Generate Image") {
                    isFocused = false
                    let selectedImageRenderer = ImageRenderer(content: currentImage)
                    let maskRenderer = ImageRenderer(content: currentImage.reverseMask { SwiftBetaCanvas(lines: $lines, currentLineWidth: 30) })
                    
                    Task {
                        guard let selecteduiImage = selectedImageRenderer.uiImage,
                              let selectedPNGData = selecteduiImage.pngData(),
                              let maskuiImage = maskRenderer.uiImage,
                              let maskPNGData = maskuiImage.pngData() else {
                            return
                        }
                        
                        await viewModel.editImage(prompt: text, imageMask: selectedPNGData, maskData: maskPNGData)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
            }
            .padding(.vertical, 12)
        }
    }
}

#Preview {
    EditImageView()
}
