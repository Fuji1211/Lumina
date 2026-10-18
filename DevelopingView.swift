import SwiftUI

struct DevelopingView: View {
    let image: UIImage?
    let onComplete: () -> Void
    @State private var progress: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color(hex: "F7F1E8").ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Developing...")
                    .font(.system(size: 32, weight: .light, design: .serif))
                
                Text("Creating your moment.")
                    .foregroundStyle(.secondary)
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 250)
                        .clipped()
                        .padding(12)
                        .padding(.bottom, 30)
                        .background(Color.white)
                        .shadow(radius: 8)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 250)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(Color(hex: "C9A27C"))
                    .frame(width: 220)
                
                Text("Good things take a moment.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 4)) {
                progress = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
                onComplete()
            }
        }
    }
}
