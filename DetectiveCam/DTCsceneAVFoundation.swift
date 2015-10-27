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

	var capturingModule: DTCmoduleCapture! = nil


	deinit {
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view, typically from a nib.

		capturingModule = DTCmoduleCapture();
	}


	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated);

		if (capturingModule.sampleDisplayLayer == nil) {
			capturingModule.sampleDisplayLayer = AVSampleBufferDisplayLayer()
			capturingModule.sampleDisplayLayer.bounds = opencvScreen.bounds
			capturingModule.sampleDisplayLayer.position = CGPointMake(CGRectGetMidX(opencvScreen.bounds), CGRectGetMidY(opencvScreen.bounds))
			capturingModule.sampleDisplayLayer.videoGravity = AVLayerVideoGravityResizeAspect

			opencvScreen.layer.addSublayer(capturingModule.sampleDisplayLayer);
		}
	}
}

