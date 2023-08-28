
import MetalKit


struct Uniform {
    var brightness: Float
    var time: Int16
}




class Engine: MTKView {
    
    
    
    var commandQueue: MTLCommandQueue!


    var pixelsPass: MTLComputePipelineState!





    var UniformBuffer: MTLBuffer!
    



    var screenSize: SIMD2<Float> { return SIMD2<Float>(Float(bounds.width * 2), Float(bounds.height * 2)) }
    
    

    func update() {
        let ptr = UniformBuffer.contents().bindMemory(to: Uniform.self, capacity: 1)
        ptr.pointee.time += 1

    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        self.framebufferOnly = false
        self.device = MTLCreateSystemDefaultDevice()
        self.commandQueue = device?.makeCommandQueue()
        self.preferredFramesPerSecond = 60
        
        layer?.isOpaque = true

        var uniform = Uniform(brightness: 1, time: 0)
        UniformBuffer = device?.makeBuffer(bytes: &uniform, length: MemoryLayout<Uniform>.stride, options: [])!
        
        makeLib()
        
    }
    
    func makeLib() {
        let library = device?.makeDefaultLibrary()
        let pixels = library?.makeFunction(name: "pixels")
        
        do {
            pixelsPass = try device?.makeComputePipelineState(function: pixels!)
            
            
        } catch {
            print(error)
        }
    }
    
}
extension Engine {
    override func draw(_ dirtyRect: NSRect) {
        
        


        guard let drawable: CAMetalDrawable = currentDrawable else { return }

        let commandBuffer: MTLCommandBuffer? = commandQueue.makeCommandBuffer()
        let commandEncoder: MTLComputeCommandEncoder? = commandBuffer?.makeComputeCommandEncoder()

        var threadsPerGrid: MTLSize
        var threadsPerThreadgroup: MTLSize

        let w: Int = pixelsPass.threadExecutionWidth
        let h: Int = pixelsPass.maxTotalThreadsPerThreadgroup / w

        commandEncoder?.setComputePipelineState(pixelsPass)
        commandEncoder?.setBuffer(UniformBuffer, offset: 0, index: 1)
        commandEncoder?.setTexture(drawable.texture, index: 0)
        commandEncoder?.setTexture(drawable.texture, index: 1)
        threadsPerGrid = MTLSize(width: drawable.texture.width, height: drawable.texture.height, depth: 1)
        threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)
        commandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        

        commandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        update()
    }
}
