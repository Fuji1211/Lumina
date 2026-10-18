import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let ciContext = CIContext()
    
    @Published var currentStock: FilmStock = .portra
    @Published var isFlashOn = false
    
    private var currentCamera: AVCaptureDevice.Position = .back
    
    override init() {
        super.init()
        setupSession()
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { self.startSession() }
            }
        default:
            break
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCamera),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    func switchCamera() {
        currentCamera = currentCamera == .back ? .front : .back
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        setupSession()
        session.commitConfiguration()
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        if isFlashOn && currentStock == .flash {
            settings.flashMode = .on
        }
        output.capturePhoto(with: settings, delegate: PhotoCaptureDelegate { image in
            completion(self.applyEffects(to: image))
        })
    }
    
    private func applyEffects(to image: UIImage?) -> UIImage? {
        guard let image = image, let ciImage = CIImage(image: image) else { return image }
        var output = ciImage
        
        // Haze for foggy
        if currentStock == .foggy || currentStock == .expired {
            let blur = CIFilter.gaussianBlur()
            blur.inputImage = output
            blur.radius = currentStock == .foggy ? 3.0 : 1.5
            output = blur.outputImage?.cropped(to: ciImage.extent) ?? output
        }
        
        // Vignette
        let vignette = CIFilter.vignette()
        vignette.inputImage = output
        vignette.intensity = 1.5
        vignette.radius = 1.2
        output = vignette.outputImage ?? output
        
        // Grain
        if let noise = CIFilter.randomGenerator().outputImage?.cropped(to: ciImage.extent) {
            let grain = noise.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 0.15, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 0.12, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0.10, z: 0, w: 0)
            ])
            output = output.applyingFilter("CIAdditionCompositing", parameters: ["inputBackgroundImage": grain])
        }
        
        // Highlight crush
        let highlight = CIFilter.highlightShadowAdjust()
        highlight.inputImage = output
        highlight.highlightAmount = 0.35
        output = highlight.outputImage ?? output
        
        // Flash blowout
        if currentStock == .flash && isFlashOn {
            let exp = CIFilter.exposureAdjust()
            exp.inputImage = output
            exp.ev = 1.6
            output = exp.outputImage ?? output
        }
        
        guard let cgImage = ciContext.createCGImage(output, from: output.extent) else { return image }
        return UIImage(cgImage: cgImage)
    }
}

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let completion: (UIImage?) -> Void
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            completion(nil)
            return
        }
        completion(image)
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Live preview processing can be added here with Metal for better performance
    }
}
