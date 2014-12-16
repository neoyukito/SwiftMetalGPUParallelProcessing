//
//  ViewController.Swift
//  SwiftMetalProcessing
//
//  Created by Amund Tveit on 15/12/14.
//  Copyright (c) 2014 Amund Tveit. All rights reserved.
//
import UIKit
import Metal
import QuartzCore
import Darwin

class ViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    
        // prepare original input data – a Swift array
        var myvector = [Float](count: 123456, repeatedValue: 0)
        for (index, value) in enumerate(myvector) {
            myvector[index] = Float(index)
        }
        
        // initialize Metal
        var (device, commandQueue, defaultLibrary, commandBuffer, computeCommandEncoder) = initMetal()

        
        // set up a compute pipeline with Sigmoid function and add it to encoder
        let sigmoidProgram = defaultLibrary.newFunctionWithName("sigmoid")
        var pipelineErrors = NSErrorPointer()
        var computePipelineFilter = device.newComputePipelineStateWithFunction(sigmoidProgram!, error: pipelineErrors)
        computeCommandEncoder.setComputePipelineState(computePipelineFilter!)
        
      
        computeCommandEncoder.setComputePipelineState(computePipelineFilter!)
        
        
        // calculate byte length of input data - myvector
        var myvectorByteLength = myvector.count*sizeofValue(myvector[0])
        
        // create a MTLBuffer - input data that the GPU and Metal and produce
        var inVectorBuffer = device.newBufferWithBytes(&myvector, length: myvectorByteLength, options: nil)
        
        //   set the input vector for the Sigmoid() function, e.g. inVector
        //    atIndex: 0 here corresponds to buffer(0) in the Sigmoid function
        computeCommandEncoder.setBuffer(inVectorBuffer, offset: 0, atIndex: 0)
        
        // d. create the output vector for the Sigmoid() function, e.g. outVector
        //    atIndex: 1 here corresponds to buffer(1) in the Sigmoid function
        var resultdata = [Float](count:myvector.count, repeatedValue: 0)
        var outVectorBuffer = device.newBufferWithBytes(&resultdata, length: myvectorByteLength, options: nil)
        computeCommandEncoder.setBuffer(outVectorBuffer, offset: 0, atIndex: 1)
        
        // hardcoded to 32 for now (recommendation: read about threadExecutionWidth)
        var threadsPerGroup = MTLSize(width:32,height:1,depth:1)
        var numThreadgroups = MTLSize(width:(myvector.count+31)/32, height:1, depth:1)
        computeCommandEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)

        computeCommandEncoder.endEncoding()

        let start = CACurrentMediaTime()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        let stop = CACurrentMediaTime()
        let deltaMicroseconds = (stop-start) * (1.0*10e6)
        println("cold GPU: runtime in microsecs : \(deltaMicroseconds)")
        
        /*
        let start2 = CACurrentMediaTime()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        let stop2 = CACurrentMediaTime()
        let deltaMicroseconds2 = (stop2-start2) * (1.0*10e6)
        println("warm GPU: runtime in microsecs : \(deltaMicroseconds2)")

*/
     

        
        // a. Get GPU data
        // outVectorBuffer.contents() returns UnsafeMutablePointer roughly equivalent to char* in C
        var data = NSData(bytesNoCopy: outVectorBuffer.contents(),
            length: myvector.count*sizeof(Float), freeWhenDone: false)
        // b. prepare Swift array large enough to receive data from GPU
        var finalResultArray = [Float](count: myvector.count, repeatedValue: 0)
        
        // c. get data from GPU into Swift array
        data.getBytes(&finalResultArray, length:myvector.count * sizeof(Float))
        
        // d. YOU'RE ALL SET!        exit(0)
        println(finalResultArray[0]) // should be 0.5
        
        let start3 = CACurrentMediaTime()

        // timing without
        for (index, value) in enumerate(myvector) {
            finalResultArray[index] = 1.0 / (1.0 + exp(-myvector[index]))
        }
        
        let stop3 = CACurrentMediaTime()
        let deltaMicroseconds3 = (stop3-start3) * (1.0*10e6)
        println("CPU: runtime in microsecs : \(deltaMicroseconds3)")
        
        let relativeSpeed = deltaMicroseconds3/deltaMicroseconds
        println("relativespeed = \(relativeSpeed)")
        
        
        exit(0)
    }
    
    func initMetal() -> (MTLDevice, MTLCommandQueue, MTLLibrary, MTLCommandBuffer,
        MTLComputeCommandEncoder){
            // Get access to iPhone or iPad GPU
            var device = MTLCreateSystemDefaultDevice()
            
            // Queue to handle an ordered list of command buffers
            var commandQueue = device.newCommandQueue()
            
            // Access to Metal functions that are stored in Shaders.metal file, e.g. sigmoid()
            var defaultLibrary = device.newDefaultLibrary()
            
            // Buffer for storing encoded commands that are sent to GPU
            var commandBuffer = commandQueue.commandBuffer()
            
            // Encoder for GPU commands
            var computeCommandEncoder = commandBuffer.computeCommandEncoder()
            
            return (device, commandQueue, defaultLibrary!, commandBuffer, computeCommandEncoder)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        if(self.isViewLoaded() && self.view.window == nil) {
            self.view = nil
        }
    }
    
    
}

