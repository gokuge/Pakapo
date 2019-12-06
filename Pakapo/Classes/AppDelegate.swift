//
//  AppDelegate.swift
//  Pakapo
//
//  Created by gokuge on 2019/12/06.
//  Copyright © 2019 gokuge. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var initFullScreenMode:(() -> Void)!
    
    var menuFileOpenClosure:(() -> Void)!
    var menuQuitPakapoClosure:(() -> Void)!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        initFullScreenMode()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func menuQuitApplication(_ sender: Any) {
        print("AppDelegate:actionMenuItemSelected")
        menuQuitPakapoClosure()
    }
    
    @IBAction func menuOpenImage(_ sender: NSMenuItem) {
        print("AppDelegate:actionMenuItemSelected")
        menuFileOpenClosure()
    }

}

