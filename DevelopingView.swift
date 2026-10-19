import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct DevelopingView: View {
    let image: UIImage?
    let onComplete: () -> Void
    
    @State private var isDarkroom = false
    @State private var modifiedImage: UIImage?
    
    // Adjustable parameters
    @State private var temperature: Double = 20.0      // 18-24
    @State private var agitation: Double = 0.5         // 0-1 (intensity)
    @State private var developTime: Double = 1.0       // 0.5-1.5 relative
    
    private let ciContext = CIContext()
    
    var body: some View {
        ZStack {
            Color(hex: "F7F1E8").ignoresSafeArea()
            
            if isDarkroom {
                darkroomView
            } else {
                normalView
            }
        }
        .onAppear {
            modifiedImage = image
        }
        .onChange(of: temperature) { _ in applyAdjustments() }
        .onChange(of: agitation) { _ in applyAdjustments() }
        .onChange(of: developTime) { _ in applyAdjustments() }
    }
    
    private var normalView: some View {
        VStack(spacing: 24) {
            Text("Developing...")
                .font(.system(size: 32, weight: .light, design: .serif))
            
            Text("Creating your moment.")
                .foregroundStyle(.secondary)
            
            photoPreview
            
            Button("暗室で現像する") {
                isDarkroom = true
                applyAdjustments()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(hex: "C9A27C"))
            .foregroundStyle(.white)
            .clipShape(Capsule())
            
            Button("Done") {
                saveImage()
                onComplete()
            }
            .padding(.top, 8)
        }
    }
    
    private var darkroomView: some View {
        VStack(spacing: 16) {
            Text("暗室")
                .font(.system(size: 22, weight: .light, design: .serif))
                .padding(.top, 8)
            
            photoPreview
                .frame(height: 280)
            
            VStack(spacing: 20) {
                controlRow(title: "温度", value: temperature, range: 18...24, format: "%.0f°C") { temperature = $0 }
                controlRow(title: "撹拌", value: agitation, range: 0...1, format: "%.0f%%") { agitation = $0 }
                controlRow(title: "時間", value: developTime, range: 0.5...1.5, format: "%.1fx") { developTime = $0 }
            }
            .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button("戻る") {
                    isDarkroom = false
                    modifiedImage = image
                }
                .foregroundStyle(.secondary)
                
                Button("完了") {
                    saveImage()
                    onComplete()
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color(hex: "C9A27C"))
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .padding(.bottom, 16)
        }
    }
    
    private func controlRow(title: String, value: Double, range: ClosedRange<Double>, format: String, onChange: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: format, value * (title == "撹拌" ? 100 : 1)))
                    .font(.caption.monospacedDigit())
            }
            Slider(value: Binding(
                get: { value },
                set: { onChange($0) }
            ), in: range)
            .tint(Color(hex: "C9A27C"))
        }
    }
    
    private var photoPreview: some View {
        Group {
            if let img = modifiedImage ?? image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280)
                    .padding(12)
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 200, height: 250)
            }
        }
    }
    
    private func applyAdjustments() {
        guard let baseImage = image, let ciImage = CIImage(image: baseImage) else { return }
        
        var output = ciImage
        
        // Temperature affects color temperature and contrast
        let tempDelta = (temperature - 20.0) / 4.0 // -0.5 to +1.0
        let tempFilter = CIFilter.temperatureAndTint()
        tempFilter.inputImage = output
        tempFilter.neutral = CIVector(x: 6500 + tempDelta * 800, y: 0)
        tempFilter.targetNeutral = CIVector(x: 6500, y: 0)
        output = tempFilter.outputImage ?? output
        
        // Agitation affects grain and slight contrast
        let grainAmount = Float(agitation) * 0.25
        if grainAmount > 0.01, let noise = CIFilter.randomGenerator().outputImage?.cropped(to: ciImage.extent) {
            let grain = noise.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: grainAmount, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: grainAmount * 0.8, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: grainAmount * 0.6, z: 0, w: 0)
            ])
            output = output.applyingFilter("CIAdditionCompositing", parameters: ["inputBackgroundImage": grain])
        }
        
        // Develop time affects overall contrast and exposure
        let timeFactor = Float(developTime)
        let controls = CIFilter.colorControls()
        controls.inputImage = output
        controls.contrast = 0.9 + timeFactor * 0.25
        controls.saturation = 0.95 + (timeFactor - 1.0) * 0.1
        output = controls.outputImage ?? output
        
        if let cgImage = ciContext.createCGImage(output, from: output.extent) {
            modifiedImage = UIImage(cgImage: cgImage)
        }
    }
    
    private func saveImage() {
        guard let img = modifiedImage ?? image else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
    }
}
