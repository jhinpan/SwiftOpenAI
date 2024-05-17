import SwiftUI

struct VariationImageView: View {
    var viewModel = VariationImageViewModel()
    @State var selectedImage: Image?
    @State var emptyImage: Image = Image(systemName: "photo.on.rectangle.angled")
    @State var showCamera: Bool = false
    @State var showGallery: Bool = false
    
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
            Text("Create a variation of the selected image")
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
            
            HStack {
                Spacer()
                Button("🪄 Generate Image") {
                    let selectedImageRenderer = ImageRenderer(content: currentImage)

                    Task {
                        guard let selecteduiImage = selectedImageRenderer.uiImage,
                              let selectedPNGData = selecteduiImage.pngData() else {
                            return
                        }
                        
                        await viewModel.variationImage(imageMask: selectedPNGData)
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
    VariationImageView()
}
