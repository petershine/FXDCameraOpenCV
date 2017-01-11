//
//  DTCpreviewCapture.swift
//  DetectiveCam
//
//  Created by petershine on 10/5/15.
//  Copyright © 2015 fXceed. All rights reserved.
//

import Foundation
import UIKit

import AVFoundation;


class DTCpreviewCapture : UIView {

	override class var layerClass : AnyClass {
		return AVCaptureVideoPreviewLayer.classForCoder()
	}


	var session : AVCaptureSession {
		get {
			return (self.layer as? AVCaptureVideoPreviewLayer)!.session
		}
		set (newSession) {
			(self.layer as? AVCaptureVideoPreviewLayer)!.session = newSession
		}
	}
}
