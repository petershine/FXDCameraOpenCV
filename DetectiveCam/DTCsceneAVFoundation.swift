//
//  DTCsceneAVFoundation.swift
//  DetectiveCam
//
//  Created by petershine on 10/5/15.
//  Copyright © 2015 fXceed. All rights reserved.
//

import UIKit

import AVFoundation


class DTCsceneAVFoundation: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

	@IBOutlet weak var capturedPreview: DTCpreviewCapture!


	var capturingQueue : dispatch_queue_t! = nil
	var shouldRunSession : Bool = false

	var captureSession : AVCaptureSession! = nil
	var captureVideoInput : AVCaptureDeviceInput! = nil

	var videoOutputQueue : dispatch_queue_t! = nil
	var captureVideoOutput : AVCaptureVideoDataOutput! = nil


	deinit {
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}


	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.

		capturingQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)

		let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)

		if (authorizationStatus != .Authorized) {
			print(authorizationStatus)

			dispatch_suspend(capturingQueue)

			AVCaptureDevice
			.requestAccessForMediaType(AVMediaTypeVideo,
				completionHandler: { (granted : Bool) -> Void in
					print(granted)

					self.shouldRunSession = granted

					dispatch_resume(self.capturingQueue)
			})
		}
		else {
			shouldRunSession = true
		}


		captureSession = AVCaptureSession()
		capturedPreview.session = self.captureSession

		captureVideoOutput = AVCaptureVideoDataOutput();
		captureVideoOutput.alwaysDiscardsLateVideoFrames = true

		captureVideoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: UInt(kCVPixelFormatType_32BGRA)]
		videoOutputQueue = dispatch_queue_create("outputQueue", DISPATCH_QUEUE_SERIAL)




		dispatch_async(capturingQueue) { () -> Void in
			guard (self.shouldRunSession) else {
				self.captureSession.stopRunning()
				return
			}


			var videoDevice : AVCaptureDevice! = nil
			let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)

			for device in devices as! [AVCaptureDevice] {
				if (device.position == .Back) {
					videoDevice = device
					break
				}
			}


			do {
				self.captureVideoInput = try AVCaptureDeviceInput(device: videoDevice)
			}
			catch {
			}


			self.captureSession.beginConfiguration()

			if (self.captureSession.canAddInput(self.captureVideoInput)) {
				self.captureSession.addInput(self.captureVideoInput)
			}
			else {
				self.shouldRunSession = false
			}

			if (self.captureSession.canAddOutput(self.captureVideoOutput)) {
				self.captureVideoOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)
				self.captureSession.addOutput(self.captureVideoOutput)
			}

			self.captureSession.commitConfiguration()


			self.captureSession.startRunning()
		}
	}


	func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
		let pixelbuffer : CVPixelBufferRef! = CMSampleBufferGetImageBuffer(sampleBuffer)
		print(pixelbuffer)
	}
}

