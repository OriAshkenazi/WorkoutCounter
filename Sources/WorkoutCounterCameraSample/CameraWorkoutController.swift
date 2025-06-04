#if canImport(AVFoundation) && canImport(Vision) && canImport(UIKit)
import UIKit
import AVFoundation
import Vision
import WorkoutCounter

/// Sample controller that streams camera frames to Vision and WorkoutCounter.
public final class CameraWorkoutController: NSObject {
    private let session = AVCaptureSession()
    private let visionQueue = DispatchQueue(label: "vision.queue")
    private let engine = StreamingWorkoutEngine()
    private let performance = PerformanceController()

    public override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        session.addInput(input)
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "capture.queue"))
        session.addOutput(output)
    }

    public func start() { session.startRunning() }
    public func stop() { session.stopRunning() }

    private func handleObservation(_ obs: VNHumanBodyPoseObservation, visionTime: TimeInterval) {
        let pose = PoseObservation(visionObservation: obs)
        let sample = poseSample(from: pose, at: CFAbsoluteTimeGetCurrent())
        engine.recordVisionProcessingTime(visionTime)
        let quality = performance.getOptimalQuality()
        guard engine.shouldProcessFrame(sample, quality: quality) else {
            return
        }
        _ = engine.processFrame(sample)
    }
}

extension CameraWorkoutController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        visionQueue.async { [weak self] in
            guard let self = self else { return }
            let start = CFAbsoluteTimeGetCurrent()
            defer {
                let elapsed = CFAbsoluteTimeGetCurrent() - start
                self.performance.recordFrameTime(elapsed)
                print("Total frame duration: \(elapsed)")
            }
            guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let request = VNDetectHumanBodyPoseRequest()
            let handler = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])
            do {
                let visionStart = CFAbsoluteTimeGetCurrent()
                try handler.perform([request])
                let visionElapsed = CFAbsoluteTimeGetCurrent() - visionStart
                if let result = request.results?.first as? VNHumanBodyPoseObservation {
                    self.handleObservation(result, visionTime: visionElapsed)
                }
            } catch {
                print("Vision error: \(error)")
            }
        }
    }
}
#endif
