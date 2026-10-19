import SwiftUI
import AVFoundation

enum FilmStock: String, CaseIterable, Identifiable {
    case portra = "Portra 400"
    case flash = "Disposable Flash"
    case foggy = "Foggy SLR"
    case expired = "Expired Film"
    
    var id: String { rawValue }
}

struct ContentView: View {
    @StateObject private var camera = CameraManager()
    @State private var selectedStock: FilmStock = .portra
    @State private var isFlashOn = false
    @State private var showDeveloping = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            CameraPreview(session: camera.session)
                .ignoresSafeArea()
                .opacity(showDeveloping ? 0 : 1)
            
            if showDeveloping {
                DevelopingView(image: capturedImage) {
                    showDeveloping = false
                }
            }
            
            VStack {
                HStack {
                    Text("LUMINA")
                        .font(.system(size: 20, weight: .light, design: .serif))
                        .tracking(4)
                    Spacer()
                    Text(selectedStock.rawValue)
                        .font(.caption)
                        .opacity(0.7)
                }
                .padding(.horizontal)
                .padding(.top, 60)
                
                Spacer()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(FilmStock.allCases) { stock in
                            Button(stock.rawValue.split(separator: " ").first.map(String.init) ?? "") {
                                selectedStock = stock
                                camera.currentStock = stock
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedStock == stock ? Color(hex: "C9A27C") : Color.white.opacity(0.15))
                            .foregroundStyle(selectedStock == stock ? .black : .white)
                            .clipShape(Capsule())
                            .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                }
                
                HStack {
                    Button(isFlashOn ? "FLASH ON" : "FLASH") {
                        isFlashOn.toggle()
                        camera.isFlashOn = isFlashOn
                    }
                    .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button {
                        camera.capturePhoto { image in
                            capturedImage = image
                            showDeveloping = true
                        }
                    } label: {
                        Circle()
                            .strokeBorder(Color(hex: "F5E6D3"), lineWidth: 3)
                            .frame(width: 72, height: 72)
                            .background(Circle().fill(Color(hex: "C9A27C").opacity(0.8)))
                    }
                    
                    Spacer()
                    
                    Button("FLIP") {
                        camera.switchCamera()
                    }
                    .foregroundStyle(.white)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            camera.checkPermission()
            camera.currentStock = selectedStock
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
