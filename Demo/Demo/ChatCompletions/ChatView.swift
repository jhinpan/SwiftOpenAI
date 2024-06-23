import SwiftUI

struct ChatView: View {
    @Binding var viewModel: ChatCompletionsViewModel
    @State var prompt: String = "Can you show which modules we have "
    
    var body: some View {
        VStack {
            ConversationView(viewModel: $viewModel)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Spacer()
            
            HStack {
                TextField("Write something for GPT-Allybits", text: $prompt, axis: .vertical)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(25)
                    .lineLimit(6)
                    .onSubmit {
                        Task {
                            await viewModel.send(message: prompt)
                            prompt = ""
                        }
                    }
                Button(action: {
                    Task {
                        await viewModel.send(message: prompt)
                        prompt = ""
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
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Toggle(isOn: $viewModel.isStream) {
                    HStack {
                        Text("Stream")
                            .bold()
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
        }
    }
}

//#Preview {
//    ChatView(viewModel: .constant(.init()))
//}
