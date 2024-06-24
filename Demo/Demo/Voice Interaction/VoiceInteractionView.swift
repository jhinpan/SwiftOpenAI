import SwiftUI
import AVKit

struct VoiceInteractionView: View {
    @ObservedObject var viewModel: VoiceInteractionViewModel
    @State private var isRecording = false
    
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
                
                if viewModel.isLoadingTextToSpeechAudio == .isLoading {
                    TypingIndicatorView()
                        .padding(.top, 60)
                } else {
                    if viewModel.isListening {
                        Text("Listening...")
                            .font(.system(size: 18))
                            .bold()
                            .padding(.top, 60)
                    } else if viewModel.isLoadingTextToSpeechAudio == .finishedPlaying || viewModel.isLoadingTextToSpeechAudio == .finishedLoading {
                        Text("Response: \(viewModel.responseText)")
                            .font(.system(size: 18))
                            .bold()
                            .padding(.top, 60)
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: {
                isRecording.toggle()
                if isRecording {
                    viewModel.startRecording()
                } else {
                    viewModel.stopRecording()
                }
            }) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(isRecording ? .red : .blue)
            }
            .padding(.top, 20)
            
            Spacer()
            
            VStack(alignment: .leading) {
                Text("Log:")
                    .font(.title2)
                    .padding(.bottom, 10)
                
                ScrollView {
                    ForEach(viewModel.log, id: \.self) { logEntry in
                        Text(logEntry)
                            .padding(.vertical, 2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
        }
        .padding(.top)
    }
}

//#Preview {
//    VoiceInteractionView(viewModel: VoiceInteractionViewModel())
//}
