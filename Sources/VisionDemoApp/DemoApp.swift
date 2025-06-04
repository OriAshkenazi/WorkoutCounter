#if os(iOS) && canImport(AVFoundation) && canImport(Vision) && canImport(UIKit)
import UIKit
import AVFoundation
import Vision
import WorkoutCounter

/// Simple controller that feeds wrist and shoulder positions into the engine.
final class VisionDemoController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "VisionDemo.queue")
    private let engine = StreamingWorkoutEngine()
    private var extractor = StreamingFeatureExtractor()

    override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        session.addInput(input)
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: queue)
        session.addOutput(output)
    }

    func start() { session.startRunning() }
    func stop() { session.stopRunning() }

    private func processObservation(_ obs: VNHumanBodyPoseObservation, visionTime: TimeInterval) {
        let pose = PoseObservation(visionObservation: obs)
        let frame = PoseFrame(time: CFAbsoluteTimeGetCurrent(), observation: pose)
        engine.recordVisionProcessingTime(visionTime)
        let features = extractor.processNewFrame(frame)
        _ = engine.processFrame(frame)
        print("intensity: \(features.movementIntensity) symmetry: \(features.symmetry)")
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let handler = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])
            let request = VNDetectHumanBodyPoseRequest()
            do {
                let start = CFAbsoluteTimeGetCurrent()
                try handler.perform([request])
                let visionElapsed = CFAbsoluteTimeGetCurrent() - start
                if let result = request.results?.first as? VNHumanBodyPoseObservation {
                    self.processObservation(result, visionTime: visionElapsed)
                }
            } catch {
                print("Vision error: \(error)")
            }
        }
    }
}

@main
class DemoApp: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private let controller = VisionDemoController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        controller.start()
        return true
    }
}
#else
@main
struct DemoStub {
    static func main() {
        print("VisionDemoApp is available on iOS only")
    }
}
#endif
