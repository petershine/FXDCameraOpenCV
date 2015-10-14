//
//  DTCsceneOpenCV.swift
//  DetectiveCam
//
//  Created by petershine on 10/9/15.
//  Copyright © 2015 fXceed. All rights reserved.
//

import UIKit

class DTCsceneOpenCV: UIViewController {

	@IBOutlet weak var opencvScreen: UIImageView!
	@IBOutlet weak var logDisplay: UITextView!

	var opencvModule : DTCmoduleOpenCV! = nil


	deinit {
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}


    override func viewDidLoad() {
        super.viewDidLoad()

		opencvModule = DTCmoduleOpenCV();
		opencvModule.opencvScene = self;
		opencvModule.prepareWithOpenCVpreview(opencvScreen);
    }


	override func prefersStatusBarHidden() -> Bool {
		return true
	}


	func logCoefficientArray(coefficientArray: [AnyObject]) {
		let integerArray = [coefficientArray[0] as! Int,
			coefficientArray[1] as! Int,
			coefficientArray[2] as! Int]

		let floatArray = [coefficientArray[0] as! Float,
			coefficientArray[1] as! Float,
			coefficientArray[2] as! Float]


		dispatch_async(dispatch_get_main_queue()) { () -> Void in
			self.logDisplay.text = "\(integerArray)\n\(floatArray)"
		}
	}


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
