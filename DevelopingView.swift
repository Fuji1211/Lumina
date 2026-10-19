import SwiftUI
import CoreMotion

struct DevelopingView: View {
    let image: UIImage?
    let onComplete: () -> Void
    @State private var progress: CGFloat = 0
    @State private var isInteractive = false
    @State private var agitationCount = 0
    @State private var modifiedImage: UIImage?
    @State private var temperature: Double = 20.0
    
    private let motionManager = CMMotionManager()
    
    var body: some View {
        ZStack {
            Color(hex: "F7F1E8").ignoresSafeArea()
            
            if isInteractive {
                interactiveView
            } else {
                normalView
            }
        }
        .onAppear {
            modifiedImage = image
        }
    }
    
    private var normalView: some View {
        VStack(spacing: 24) {
            Text("Developing...")
                .font(.system(size: 32, weight: .light, design: .serif))
            
            Text("Creating your moment.")
                .foregroundStyle(.secondary)
            
            photoPreview
            
            Button("暗室で現像する") {
                isInteractive = true
                startMotionDetection()
            }
            .padding()
            .background(Color(hex: "C9A27C"))
            .foregroundStyle(.white)
            .clipShape(Capsule())
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(Color(hex: "C9A27C"))
                .frame(width: 220)
            
            Button("Done") {
                saveImage()
                onComplete()
            }
            .padding(.top)
        }
        .onAppear {
            withAnimation(.linear(duration: 4)) {
                progress = 1.0
            }
        }
    }
    
    private var interactiveView: some View {
        VStack(spacing: 20) {
            Text("撹拌中...")
                .font(.title2)
            
            Text("端末を傾けるかタップして撹拌")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            photoPreview
                .onTapGesture {
                    agitate()
                }
            
            Text("撹拌回数: \(agitationCount)")
            
            VStack {
                Text("温度: \(Int(temperature))°C")
                Slider(value: $temperature, in: 18...24)
            }
            .padding(.horizontal)
            
            Button("現像完了") {
                stopMotion()
                saveImage()
                onComplete()
            }
            .padding()
            .background(Color(hex: "C9A27C"))
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
    }
    
    private var photoPreview: some View {
        Group {
            if let img = modifiedImage ?? image {
                Image(uiImage: img)
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
        }
    }
    
    private func agitate() {
        agitationCount += 1
        // Simple effect: slightly increase grain or contrast based on agitation
        if let base = image, let ci = CIImage(image: base) {
            let contrast = CIFilter.colorControls()
            contrast.inputImage = ci
            contrast.contrast = 1.0 + Float(agitationCount) * 0.02
            if let output = contrast.outputImage,
               let cg = CIContext().createCGImage(output, from: output.extent) {
                modifiedImage = UIImage(cgImage: cg)
            }
        }
    }
    
    private func startMotionDetection() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.2
            motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
                if let m = motion, abs(m.attitude.pitch) > 0.5 || abs(m.attitude.roll) > 0.5 {
                    agitate()
                }
            }
        }
    }
    
    private func stopMotion() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func saveImage() {
        guard let img = modifiedImage ?? image else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
    }
}
