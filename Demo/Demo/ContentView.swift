import SwiftUI
import SwiftOpenAI

struct ContentView: View {
    @State var chatCompletionsViewModel: ChatCompletionsViewModel = .init()
    @State var createImagesViewModel: CreateImageViewModel = .init()
    @State var editImageViewModel: EditImageViewModel = .init()
    @State var variationImageViewModel: VariationImageViewModel = .init()
    @State var createAudioViewModel: CreateAudioViewModel = .init()
    @State var createTranscriptViewModel: CreateTranscriptViewModel = .init()
    @State var createTranslationViewModel: CreateTranslationViewModel = .init()
    @State var visionViewModel: VisionViewModel = .init()
    
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    ChatView(viewModel: $chatCompletionsViewModel)
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle("Conversations")
                } label: {
                    HStack {
                        Image(systemName: "text.bubble")
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .padding(4)
                            .background(.blue.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading) {
                            Text("Text Generation")
                                .font(.system(size: 18))
                                .bold()
                            Text("Learn how to generate and process text")
                        }
                    }
                }
                NavigationLink {
                    CreateImagesView(viewModel: createImagesViewModel)
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle("Create Image")
                } label: {
                    HStack {
                        Image(systemName: "photo")
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .padding(4)
                            .background(.purple.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading) {
                            Text("Create Image")
                                .font(.system(size: 18))
                                .bold()
                            Text("Learn how to create images with prompts")
                        }
                    }
                }
                NavigationLink {
                    EditImageView(viewModel: editImageViewModel)
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle("Edit Image")
                } label: {
                    HStack {
                        Image(systemName: "photo.badge.checkmark.fill")
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .padding(4)
                            .background(.pink.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading) {
                            Text("Edit Image")
                                .font(.system(size: 18))
                                .bold()
                            Text("Learn how to edit images with masks and prompts")
                        }
                    }
                }
                NavigationLink {
                    VariationImageView(viewModel: variationImageViewModel)
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle("Variate Image")
                } label: {
                    HStack {
                        Image(systemName: "die.face.6.fill")
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .padding(4)
                            .background(.cyan.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading) {
                            Text("Variation Image")
                                .font(.system(size: 18))
                                .bold()
                            Text("Learn how to get a variation of images")
                        }
                    }
                }
                NavigationLink {
                    CreateAudioView(viewModel: createAudioViewModel)
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle("Create Audio")
                } label: {
                    HStack {
                        Image(systemName: "mic")
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .padding(4)
                            .background(.green.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading) {
                            Text("Text to speech")
                                .font(.system(size: 18))
                                .bold()
                            Text("Learn how to text into spoken audio")
                        }
                    }
                }
                NavigationLink {
                    CreateTranscriptView(viewModel: $createTranscriptViewModel)
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle("Transcript Audio")
                } label: {
                    HStack {
                        Image(systemName: "speaker.wave.3")
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .padding(4)
                            .background(.orange.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading) {
                            Text("Speech to Text")
                                .font(.system(size: 18))
                                .bold()
                            Text("Learn how to turn speech into text")
                        }
                    }
                }
                NavigationLink {
                    CreateTranslationView(viewModel: $createTranslationViewModel)
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle("Translate Audio")
                } label: {
                    HStack {
                        Image(systemName: "quote.bubble")
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .padding(4)
                            .background(.cyan.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading) {
                            Text("Translate Audio into English")
                                .font(.system(size: 18))
                                .bold()
                            Text("Learn how to translate speech into English")
                        }
                    }
                }
                NavigationLink {
                    VisionView(viewModel: visionViewModel)
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle("Vision")
                } label: {
                    HStack {
                        Image(systemName: "eye")
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .padding(4)
                            .background(.red.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading) {
                            Text("Vision")
                                .font(.system(size: 18))
                                .bold()
                            Text("Learn how to process image inputs with GPT-4")
                        }
                    }
                }
            }.navigationTitle("SwiftOpenAI Demo")
        }
    }
}

#Preview {
    ContentView()
}
