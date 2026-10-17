import AppKit
import MetalKit

final class EDRTriggerWindow: NSWindow {
    private let renderer: EDRRenderer

    init?(screen: NSScreen) {
        guard let device = MTLCreateSystemDefaultDevice(), let renderer = EDRRenderer(device: device) else {
            return nil
        }
        self.renderer = renderer
        let frame = NSRect(x: screen.frame.minX, y: screen.frame.maxY - 1, width: 1, height: 1)
        super.init(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)

        isReleasedWhenClosed = false
        level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()) + 1)
        collectionBehavior = [.stationary, .canJoinAllSpaces, .canJoinAllApplications, .fullScreenAuxiliary, .ignoresCycle]
        ignoresMouseEvents = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        sharingType = .none

        let view = MTKView(frame: NSRect(origin: .zero, size: frame.size), device: device)
        view.colorPixelFormat = .rgba16Float
        view.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
        view.clearColor = MTLClearColor(red: 1.6, green: 1.6, blue: 1.6, alpha: 1)
        view.preferredFramesPerSecond = 5
        (view.layer as? CAMetalLayer)?.wantsExtendedDynamicRangeContent = true
        view.delegate = renderer
        contentView = view
    }
}

private final class EDRRenderer: NSObject, MTKViewDelegate {
    private let queue: MTLCommandQueue

    init?(device: MTLDevice) {
        guard let queue = device.makeCommandQueue() else { return nil }
        self.queue = queue
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard
            let pass = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let buffer = queue.makeCommandBuffer(),
            let encoder = buffer.makeRenderCommandEncoder(descriptor: pass)
        else { return }
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }
}
