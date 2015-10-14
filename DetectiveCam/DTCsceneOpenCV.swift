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
	@IBOutlet weak var logCoefficientMatrix: UITextView!
	@IBOutlet weak var logHashDictionary: UITextView!

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


	func logCoefficientMatrix(coefficientMatrix: [AnyObject]) {
		let integerArray = [coefficientMatrix[0] as! Int,
			coefficientMatrix[1] as! Int,
			coefficientMatrix[2] as! Int]

		let floatArray = [coefficientMatrix[0] as! Float,
			coefficientMatrix[1] as! Float,
			coefficientMatrix[2] as! Float]


		dispatch_async(dispatch_get_main_queue()) { () -> Void in
			self.logCoefficientMatrix.text = "\(integerArray)\n\(floatArray)"
		}
	}

	func logHashDictionary(hashDictionary: [String:Int]) {
		dispatch_async(dispatch_get_main_queue()) { () -> Void in
			self.logHashDictionary.text = "\(hashDictionary)"
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
