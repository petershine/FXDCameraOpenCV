//
//  DTCsceneAVFoundation.swift
//  DetectiveCam
//
//  Created by petershine on 10/5/15.
//  Copyright © 2015 fXceed. All rights reserved.
//

import UIKit

import AVFoundation
import VideoToolbox


class DTCsceneAVFoundation: UIViewController {

	@IBOutlet weak var opencvScreen: UIImageView!
	@IBOutlet weak var logCoefficientMatrix: UITextView!
	@IBOutlet weak var logHashTable: UITextView!
	

	var capturingQueue : dispatch_queue_t! = nil
	var shouldRunSession : Bool = false

	var captureSession : AVCaptureSession! = nil
	var captureVideoInput : AVCaptureDeviceInput! = nil

	var videoOutputQueue : dispatch_queue_t! = nil
	var captureVideoOutput : AVCaptureVideoDataOutput! = nil

	var bufferingModule: DTCmoduleBuffer! = nil


	deinit {
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view, typically from a nib.

		captureSession = AVCaptureSession()
		captureSession.sessionPreset = AVCaptureSessionPresetiFrame1280x720
		capturingQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)


		captureVideoOutput = AVCaptureVideoDataOutput();
		captureVideoOutput.alwaysDiscardsLateVideoFrames = true
		captureVideoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: UInt(kCVPixelFormatType_32BGRA)]
		
		videoOutputQueue = dispatch_queue_create("outputQueue", DISPATCH_QUEUE_SERIAL)

		bufferingModule = DTCmoduleBuffer();


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


		dispatch_async(capturingQueue) { () -> Void in
			guard (self.shouldRunSession) else {
				self.captureSession.stopRunning()
				return
			}


			var cameraDevice : AVCaptureDevice! = nil
			let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)

			for device in devices as! [AVCaptureDevice] {
				if (device.position == .Back) {
					cameraDevice = device
					break
				}
			}

			if (cameraDevice != nil) {
				NSLog("[videoDevice supportsAVCaptureSessionPreset:AVCaptureSessionPreset1280x720]: %d", cameraDevice.supportsAVCaptureSessionPreset(AVCaptureSessionPresetiFrame1280x720))

				NSLog("cameraDevice.formats: %@", cameraDevice.formats);
			}

			let frameRateRanges: Array = cameraDevice.activeFormat.videoSupportedFrameRateRanges
			NSLog("frameRateRanges: %@", frameRateRanges);

			let defaultFrameRate: AVFrameRateRange = frameRateRanges.first as! AVFrameRateRange

			do {
				try cameraDevice.lockForConfiguration()
				cameraDevice.activeVideoMinFrameDuration = defaultFrameRate.minFrameDuration
				cameraDevice.activeVideoMaxFrameDuration = defaultFrameRate.maxFrameDuration
			}
			catch {
				print(error)
			}

			cameraDevice.unlockForConfiguration()


			do {
				self.captureVideoInput = try AVCaptureDeviceInput(device: cameraDevice)
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
				self.captureVideoOutput.setSampleBufferDelegate(self.bufferingModule, queue: self.videoOutputQueue)
				self.captureSession.addOutput(self.captureVideoOutput)
			}

			self.captureSession.commitConfiguration()


			self.captureSession.startRunning()
		}
	}
}

