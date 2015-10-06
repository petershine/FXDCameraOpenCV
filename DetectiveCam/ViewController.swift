//
//  ViewController.swift
//  DetectiveCam
//
//  Created by petershine on 10/5/15.
//  Copyright © 2015 fXceed. All rights reserved.
//

import UIKit

import AVFoundation


class ViewController: UIViewController {
	@IBOutlet weak var capturedPreview: DTCpreviewCapture!


	var session : AVCaptureSession! = nil
	var videoDeviceInput : AVCaptureDeviceInput! = nil

	var sessionQueue : dispatch_queue_t! = nil

	var shouldRunSession : Bool = false


	deinit {
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.

		session = AVCaptureSession()
		capturedPreview.session = self.session

		sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)

		let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
		print(authorizationStatus)

		if (authorizationStatus != .Authorized) {
			dispatch_suspend(sessionQueue)

			AVCaptureDevice
			.requestAccessForMediaType(AVMediaTypeVideo,
				completionHandler: { (granted : Bool) -> Void in
					print(granted)

					self.shouldRunSession = granted

					dispatch_resume(self.sessionQueue)
			})
		}
		else {
			shouldRunSession = true
		}


		dispatch_async(sessionQueue) { () -> Void in
			if (self.shouldRunSession == false) {
				self.session.stopRunning()
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
			print(videoDevice)


			do {
				self.videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
			}
			catch {
				print("Could not create video device input: \(error)");
			}


			self.session.beginConfiguration()

			if (self.session.canAddInput(self.videoDeviceInput)) {
				self.session.addInput(self.videoDeviceInput)
			}
			else {
				print("Could not add video device input to the session");
				self.shouldRunSession = false
			}

			self.session.commitConfiguration()


			self.session.startRunning()
		}
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
	}

	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
	}
}

