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
    
    let PAGE_FEED: String = "pageFeed"
    let PAGE_FEED_RIGHT: String = "right"
    let PAGE_FEED_LEFT: String = "left"
    
    @IBOutlet weak var mainMenu: NSMenu!
    
    var initFullScreenMode:(() -> Void)!
    
    var menuFileOpenClosure:(() -> Void)!
    var menuQuitPakapoClosure:(() -> Void)!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        initFullScreenMode()
        
        if let unwrappedPageFeed = UserDefaults.standard.string(forKey: PAGE_FEED) {
            if unwrappedPageFeed == PAGE_FEED_RIGHT {
                selectPageFeed(isRight: true)
            } else {
                selectPageFeed(isRight: false)
            }
        } else {
            //初回起動時を想定
            selectPageFeed(isRight: true)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func menuQuitApplication(_ sender: Any) {
        menuQuitPakapoClosure()
    }
    
    @IBAction func menuOpenImage(_ sender: NSMenuItem) {
        menuFileOpenClosure()
    }

    @IBAction func menuPageFeedRight(_ sender: Any) {
        selectPageFeed(isRight: true)
    }
    
    @IBAction func manuPageFeedLeft(_ sender: Any) {
        selectPageFeed(isRight: false)
    }
    
    func selectPageFeed(isRight: Bool) {
        let viewItem = mainMenu.item(withTag: 3)
        let rightFeedItem = viewItem?.submenu?.item(withTag: 0)
        let leftFeedItem = viewItem?.submenu?.item(withTag: 1)
        
        if isRight {
            rightFeedItem?.state = NSControl.StateValue.on
            leftFeedItem?.state = NSControl.StateValue.off
            UserDefaults.standard.set(PAGE_FEED_RIGHT, forKey: PAGE_FEED)
        } else {
            rightFeedItem?.state = NSControl.StateValue.off
            leftFeedItem?.state = NSControl.StateValue.on
            UserDefaults.standard.set(PAGE_FEED_LEFT, forKey: PAGE_FEED)
        }
    }
}

