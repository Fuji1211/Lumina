import SwiftUI
import CoreMotion
import CoreImage
import CoreImage.CIFilterBuiltins

struct DevelopingView: View {
    let image: UIImage?
    let onComplete: () -> Void
    
    @State private var isDarkroom = false
    @State private var modifiedImage: UIImage?
    @State private var agitationIntensity: Double = 0.0
    @State private var isAgitating = false
    @State private var developProgress: Double = 0.0
    
    // Frame feature
    @State private var isFrameOn = false
    @State private var frameColor: Color = Color(red: 0.1, green: 0.1, blue: 0.12)
    
    private let motionManager = CMMotionManager()
    private let ciContext = CIContext()
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Deep darkroom red
            Color(red: 0.15, green: 0.02, blue: 0.02).ignoresSafeArea()
            
            if isDarkroom {
                darkroomContent
            } else {
                entryContent
            }
        }
        .onAppear {
            modifiedImage = image
        }
        .onReceive(timer) { _ in
            if isDarkroom && isAgitating {
                developProgress = min(1.0, developProgress + 0.008)
                applyAgitationEffect()
            }
        }
    }
    
    private var entryContent: some View {
        VStack(spacing: 32) {
            Spacer()
            
            photoPreview
            
            Text("現像する")
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundStyle(Color(red: 0.9, green: 0.3, blue: 0.25))
            
            Button("暗室に入る") {
                withAnimation(.easeInOut(duration: 0.8)) {
                    isDarkroom = true
                }
                startMotion()
            }
            .font(.system(size: 17, weight: .medium))
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(Color(red: 0.6, green: 0.15, blue: 0.12))
            .foregroundStyle(.white)
            .clipShape(Capsule())
            
            Spacer()
            
            Button("保存せずに戻る") {
                onComplete()
            }
            .foregroundStyle(.white.opacity(0.5))
            .padding(.bottom, 40)
        }
    }
    
    private var darkroomContent: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Emerging photo with optional frame
            photoPreview
                .frame(height: 340)
            
            Spacer()
            
            // Frame toggle button (white square)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFrameOn.toggle()
                }
            } label: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isFrameOn ? Color.white : Color.white.opacity(0.4))
                    .frame(width: 28, height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.black.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.bottom, 20)
            
            VStack(spacing: 12) {
                Text(isAgitating ? "掹拌中" : "端末をゆっくり傾けて掹拌")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Color(red: 0.95, green: 0.4, blue: 0.35))
                
                Text("\(Int(developProgress * 100))%")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.bottom, 40)
            
            HStack(spacing: 40) {
                Button("中止") {
                    stopMotion()
                    isDarkroom = false
                    developProgress = 0
                    modifiedImage = image
                }
                .foregroundStyle(.white.opacity(0.5))
                
                Button("完了") {
                    stopMotion()
                    saveAndFinish()
                }
                .font(.system(size: 17, weight: .medium))
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(developProgress > 0.3 ? Color(red: 0.7, green: 0.2, blue: 0.15) : Color.gray.opacity(0.3))
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .disabled(developProgress < 0.3)
            }
            .padding(.bottom, 50)
        }
    }
    
    // Photo preview with rounded corners and optional background frame
    private var photoPreview: some View {
        Group {
            if let img = modifiedImage ?? image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(isFrameOn ? 24 : 0)
                    .background(
                        isFrameOn ? frameColor : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: isFrameOn ? 8 : 0))
                    .opacity(isDarkroom ? (0.3 + developProgress * 0.7) : 0.9)
                    .blur(radius: isDarkroom ? (1.0 - developProgress) * 8 : 0)
            }
        }
    }
    
    private func startMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.05
        motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let m = motion else { return }
            let pitch = abs(m.attitude.pitch)
            let roll = abs(m.attitude.roll)
            let accel = abs(m.userAcceleration.x) + abs(m.userAcceleration.y) + abs(m.userAcceleration.z)
            
            let intensity = min(1.0, (pitch + roll) * 0.4 + accel * 0.8)
            agitationIntensity = intensity
            isAgitating = intensity > 0.15
        }
    }
    
    private func stopMotion() {
        motionManager.stopDeviceMotionUpdates()
        isAgitating = false
    }
    
    private func applyAgitationEffect() {
        guard let base = image, let ci = CIImage(image: base) else { return }
        
        var output = ci
        
        // Grain increases with agitation + progress
        let grainStrength = Float(agitationIntensity * developProgress) * 0.35
        if grainStrength > 0.02, let noise = CIFilter.randomGenerator().outputImage?.cropped(to: ci.extent) {
            let grain = noise.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: grainStrength, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: grainStrength * 0.75, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: grainStrength * 0.55, z: 0, w: 0)
            ])
            output = output.applyingFilter("CIAdditionCompositing", parameters: ["inputBackgroundImage": grain])
        }
        
        // Contrast and slight exposure shift as it develops
        let controls = CIFilter.colorControls()
        controls.inputImage = output
        controls.contrast = 0.85 + Float(developProgress) * 0.35
        controls.brightness = Float(developProgress - 0.5) * 0.08
        output = controls.outputImage ?? output
        
        // Subtle red cast that fades as it develops
        let redCast = CIFilter.colorMatrix()
        redCast.inputImage = output
        let cast = Float(1.0 - developProgress) * 0.15
        redCast.rVector = CIVector(x: 1 + cast, y: 0, z: 0, w: 0)
        redCast.gVector = CIVector(x: 0, y: 1 - cast * 0.3, z: 0, w: 0)
        redCast.bVector = CIVector(x: 0, y: 0, z: 1 - cast * 0.5, w: 0)
        output = redCast.outputImage ?? output
        
        if let cg = ciContext.createCGImage(output, from: output.extent) {
            modifiedImage = UIImage(cgImage: cg)
        }
    }
    
    private func saveAndFinish() {
        if let img = modifiedImage ?? image {
            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        }
        onComplete()
    }
}
