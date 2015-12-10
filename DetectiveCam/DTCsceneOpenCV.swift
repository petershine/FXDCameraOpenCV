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

	var opencvModule : DTCmoduleOpenCV! = nil


	deinit {
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	override func prefersStatusBarHidden() -> Bool {
		return true
	}


    override func viewDidLoad() {
        super.viewDidLoad()
    }


	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		if (opencvModule == nil) {
			opencvModule = DTCmoduleOpenCV();
			opencvModule.opencvScene = self;
			opencvModule.prepareWithOpenCVpreview(opencvScreen);
		}
	}
}
