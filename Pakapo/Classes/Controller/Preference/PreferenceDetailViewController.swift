//
//  PreferenceDetailViewController.swift
//  Pakapo
//
//  Created by gokuge on 2019/12/23.
//  Copyright © 2019 gokuge. All rights reserved.
//

import Cocoa

class PreferenceDetailViewController: NSViewController {    
    
    @IBOutlet weak var slideshowSpeedValue: NSTextField!
    
    
    // MARK: - init
    override func viewWillAppear() {
        super.viewWillAppear()
        willMakeView()
    }
    
    func willMakeView() {
        slideshowSpeedValue.stringValue = String(UserDefaults.standard.float(forKey: AppDelegate.SLIDESHOW_SPEED))
    }
    
    @IBAction func changeSlideshowSpeedValue(_ sender: Any) {
        let text = sender as! NSTextField
        
        guard let value = Float(text.stringValue) else {
            return
        }
        UserDefaults.standard.set(value, forKey: AppDelegate.SLIDESHOW_SPEED)
    }
}
