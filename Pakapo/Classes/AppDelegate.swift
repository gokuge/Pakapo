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
    
    let FIRST_LAUNCH: String = "firstLaunch"
    let PAGE_FEED_RIGHT: String = "pageFeedRight"
    let SEARCH_CHILD_ENABLE: String = "searchChildEnable"
    
    @IBOutlet weak var mainMenu: NSMenu!
    
    var initFullScreenMode:(() -> Void)!
    
    //Pakapo
    var menuQuitPakapoClosure:(() -> Void)!
    
    //file
    var menuFileOpenClosure:(() -> Void)!
    
    //view
    var menuPageFeedClosure:((_ right: Bool) -> Void)!
    var menuSearchChildEnableClosure:((_ enable: Bool) -> Void)!
    
    //window
    var menuFullScreenClosure:(() -> Void)!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if UserDefaults.standard.string(forKey: FIRST_LAUNCH) == nil {
            initFirstLaunchMenu()
        } else {
            loadMenu()
        }
        
        initFullScreenMode()
    }
    
    func initFirstLaunchMenu() {
        selectPageFeed(right: true)
        toggleSearchChildEnableItem(enable: false)
        
        UserDefaults.standard.set("finishFirstLaunch", forKey: FIRST_LAUNCH)
    }
    
    func loadMenu() {
        selectPageFeed(right: UserDefaults.standard.bool(forKey: PAGE_FEED_RIGHT))
        toggleSearchChildEnableItem(enable: !UserDefaults.standard.bool(forKey: SEARCH_CHILD_ENABLE))
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
        selectPageFeed(right: true)
    }
    
    @IBAction func menuPageFeedLeft(_ sender: Any) {
        selectPageFeed(right: false)
    }
    
    @IBAction func menuSearchChildEnable(_ sender: Any) {
        toggleSearchChildEnableItem(enable: NSNumber(value: (sender as! NSMenuItem).state.rawValue).boolValue)
    }
    
    @IBAction func menuToggleFullScreen(_ sender: Any) {
        menuFullScreenClosure()
    }
    
    func selectPageFeed(right: Bool) {
        let viewItem = mainMenu.item(withTag: 3)
        let rightFeedItem = viewItem?.submenu?.item(withTag: 0)
        let leftFeedItem = viewItem?.submenu?.item(withTag: 1)
        
        if right {
            rightFeedItem?.state = NSControl.StateValue.on
            leftFeedItem?.state = NSControl.StateValue.off
            UserDefaults.standard.set(true, forKey: PAGE_FEED_RIGHT)
            menuPageFeedClosure(true)
        } else {
            rightFeedItem?.state = NSControl.StateValue.off
            leftFeedItem?.state = NSControl.StateValue.on
            UserDefaults.standard.set(false, forKey: PAGE_FEED_RIGHT)
            menuPageFeedClosure(false)
        }
    }
    
    func toggleSearchChildEnableItem(enable: Bool) {
        let viewItem = mainMenu.item(withTag: 3)
        let searchChildEnableItem = viewItem?.submenu?.item(withTag: 2)
        
        if enable {
            searchChildEnableItem?.state = NSControl.StateValue.off
            UserDefaults.standard.set(false, forKey: SEARCH_CHILD_ENABLE)
            menuSearchChildEnableClosure(false)
        } else {
            searchChildEnableItem?.state = NSControl.StateValue.on
            UserDefaults.standard.set(true, forKey: SEARCH_CHILD_ENABLE)
            menuSearchChildEnableClosure(true)
        }
        
    }
}

