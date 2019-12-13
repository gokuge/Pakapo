//
//  AppDelegate.swift
//  Pakapo
//
//  Created by gokuge on 2019/12/06.
//  Copyright © 2019 gokuge. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    let FIRST_LAUNCH: String = "firstLaunch"
    let PAGE_FEED_RIGHT: String = "pageFeedRight"
    let SEARCH_CHILD_ENABLE: String = "searchChildEnable"
    
    @IBOutlet weak var mainMenu: NSMenu!
    
    var initFullScreenMode: (() -> Void)!
    
    //Pakapo
    var menuQuitPakapoClosure: (() -> Void)!
    
    //file
    var menuFileOpenClosure: (() -> Void)!
    
    var initRootSameDirectoriesClosure: (() -> (currentIndex: Int?, directories: [URL]?))!
    var menuSameDirectoriesClosure: ((_ index: Int) -> Void)!
    
    var initOpenRecentDirectoriesClosure: (() -> [String]?)!
    var menuOpenRecentDirectoriesClosure: ((_ index: Int) -> Void)!
    
    //edit
    var menuCopyOpenClosure: (() -> Void)!
    
    //view
    var menuPageFeedClosure: ((_ right: Bool) -> Void)!
    var menuSearchChildEnableClosure: ((_ enable: Bool) -> Void)!
    
    //window
    var menuFullScreenClosure: (() -> Void)!

    // MARK: - appdelegate
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        if UserDefaults.standard.string(forKey: FIRST_LAUNCH) == nil {
            initFirstLaunchMenu()
        } else {
            loadMenu()
        }
        
        initFullScreenMode()
    }
    
    func initFirstLaunchMenu() {
        initSameDirectories()
        initOpenRecentDirectories()
        selectPageFeed(right: true)
        toggleSearchChildEnableItem(enable: false)
        
        UserDefaults.standard.set("finishFirstLaunch", forKey: FIRST_LAUNCH)
    }
    
    func loadMenu() {
        initSameDirectories()
        initOpenRecentDirectories()
        selectPageFeed(right: UserDefaults.standard.bool(forKey: PAGE_FEED_RIGHT))
        toggleSearchChildEnableItem(enable: !UserDefaults.standard.bool(forKey: SEARCH_CHILD_ENABLE))
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - menu
    func menuWillOpen(_ menu: NSMenu) {
        
        let fileItem: NSMenuItem! = mainMenu.item(withTag: 1)
        let sameDirectoriesItem: NSMenuItem! = fileItem.submenu?.item(withTag: 2)
        let openRecentItem: NSMenuItem! = fileItem.submenu?.item(withTag: 3)
        
        //tagがないのでタイトルで比較。特定のNSMenuを開いた場合に処理を行いたいが、それが複数ある場合どうするのがいいのか
        switch menu.title {
        case sameDirectoriesItem.title:
            initSameDirectories()
        case openRecentItem.title:
            initOpenRecentDirectories()
        default:
            break
        }
    }
    
    //Pakapo
    @IBAction func menuQuitApplication(_ sender: Any) {
        menuQuitPakapoClosure()
    }
    
    //file
    @IBAction func menuOpenImage(_ sender: NSMenuItem) {
        menuFileOpenClosure()
    }
    
    func initSameDirectories() {
        let fileItem: NSMenuItem! = mainMenu.item(withTag: 1)
        let sameDirectoriesItem: NSMenuItem! = fileItem.submenu?.item(withTag: 2)
        let sameDirectoriesMenu: NSMenu! = sameDirectoriesItem.submenu
        sameDirectoriesMenu.delegate = self
        sameDirectoriesMenu.removeAllItems()
        
        let result = initRootSameDirectoriesClosure()
        
        guard let unwrappedDirectories = result.directories else {
            return
        }
        
        for (index, dir) in unwrappedDirectories.reversed().enumerated() {
            let menuItem = NSMenuItem(title: dir.lastPathComponent, action: #selector(pushSameDirectory(_:)), keyEquivalent: "")
            menuItem.tag = index
            sameDirectoriesMenu.addItem(menuItem)
        }
        
        if let unwrappedCurrentIndex = result.currentIndex {
            sameDirectoriesMenu.item(withTag: unwrappedCurrentIndex)?.state = NSControl.StateValue.on
        }
    }
    
    func initOpenRecentDirectories() {
        let fileItem: NSMenuItem! = mainMenu.item(withTag: 1)
        let openRecentItem: NSMenuItem! = fileItem.submenu?.item(withTag: 3)
        let openRecentMenu: NSMenu! = openRecentItem.submenu
        openRecentMenu.delegate = self
        openRecentMenu.removeAllItems()
        
        let openRecentDirectories: [String]? = initOpenRecentDirectoriesClosure()
        
        guard let unwrappedOpenRecentDirectories = openRecentDirectories else {
            return
        }
        
        for (index, url_str) in unwrappedOpenRecentDirectories.enumerated() {
            let dir: URL = URL(string: url_str)!
            let menuItem = NSMenuItem(title: dir.lastPathComponent, action: #selector(pushOpenRecentDirectories(_:)), keyEquivalent: "")
            menuItem.tag = index
            openRecentMenu.addItem(menuItem)
        }
    }

    @objc func pushSameDirectory(_ sender: NSMenuItem) {
        menuSameDirectoriesClosure(sender.tag)
    }
    
    @objc func pushOpenRecentDirectories(_ sender: NSMenuItem) {
        menuOpenRecentDirectoriesClosure(sender.tag)
    }
    
    //edit
    @IBAction func menuCopy(_ sender: Any) {
        menuCopyOpenClosure()
    }
    
    //view
    @IBAction func menuPageFeedRight(_ sender: Any) {
        selectPageFeed(right: true)
    }
    
    @IBAction func menuPageFeedLeft(_ sender: Any) {
        selectPageFeed(right: false)
    }
    
    @IBAction func menuSearchChildEnable(_ sender: Any) {
        toggleSearchChildEnableItem(enable: NSNumber(value: (sender as! NSMenuItem).state.rawValue).boolValue)
    }
    
    //window
    @IBAction func menuToggleFullScreen(_ sender: Any) {
        menuFullScreenClosure()
    }
    
    func selectPageFeed(right: Bool) {
        let viewItem: NSMenuItem! = mainMenu.item(withTag: 3)
        let rightFeedItem: NSMenuItem! = viewItem.submenu?.item(withTag: 0)
        let leftFeedItem: NSMenuItem! = viewItem.submenu?.item(withTag: 1)
        
        if right {
            rightFeedItem.state = NSControl.StateValue.on
            leftFeedItem.state = NSControl.StateValue.off
            UserDefaults.standard.set(true, forKey: PAGE_FEED_RIGHT)
            menuPageFeedClosure(true)
        } else {
            rightFeedItem.state = NSControl.StateValue.off
            leftFeedItem.state = NSControl.StateValue.on
            UserDefaults.standard.set(false, forKey: PAGE_FEED_RIGHT)
            menuPageFeedClosure(false)
        }
    }
    
    func toggleSearchChildEnableItem(enable: Bool) {
        let viewItem: NSMenuItem! = mainMenu.item(withTag: 3)
        let searchChildEnableItem: NSMenuItem! = viewItem.submenu?.item(withTag: 2)
        
        if enable {
            searchChildEnableItem.state = NSControl.StateValue.off
            UserDefaults.standard.set(false, forKey: SEARCH_CHILD_ENABLE)
            menuSearchChildEnableClosure(false)
        } else {
            searchChildEnableItem.state = NSControl.StateValue.on
            UserDefaults.standard.set(true, forKey: SEARCH_CHILD_ENABLE)
            menuSearchChildEnableClosure(true)
        }
        
    }
    
    //help
    @IBAction func menuHelp(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://github.com/gokuge/Pakapo/blob/master/README.md")!)
    }
}

