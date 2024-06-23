import SwiftUI
import AVKit

struct VoiceInteractionView: View {
    @ObservedObject var viewModel: VoiceInteractionViewModel
    @State private var isRecording = false
    @State private var userInput = ""
    
    var body: some View {
        VStack {
            VStack {
                Text("Say something, and I'll respond with speech!")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text(viewModel.recognizedText)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                
                switch viewModel.isLoadingTextToSpeechAudio {
                case .isLoading:
                    TypingIndicatorView()
                        .padding(.top, 60)
                case .noExecuted, .finishedPlaying:
                    VStack {
                        Image(systemName: "waveform")
                            .font(.system(size: 120))
                        Button {
                            viewModel.playAudioAgain()
                        } label: {
                            Text("Tap to play the response again!")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 60)
                case .finishedLoading:
                    VStack {
                        Image(systemName: "waveform")
                            .font(.system(size: 120))
                        Button {
                            viewModel.playAudioAgain()
                        } label: {
                            Text("Tap to play the response again!")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 60)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            HStack {
                TextField("Your text here...", text: $userInput)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(25)
                
                Button(action: {
                    Task {
                        await viewModel.createSpeech(input: userInput)
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(Color.white)
                        .frame(width: 44, height: 44)
                        .background(Color.blue)
                        .cornerRadius(22)
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal)
            
            Button(action: {
                isRecording.toggle()
                if isRecording {
                    viewModel.startRecording()
                } else {
                    viewModel.stopRecording()
                    userInput = viewModel.recognizedText
                }
            }) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(isRecording ? .red : .blue)
            }
            .padding(.top, 20)
        }
        .padding(.top)
    }
}

//#Preview {
//    VoiceInteractionView(viewModel: VoiceInteractionViewModel())
//}
