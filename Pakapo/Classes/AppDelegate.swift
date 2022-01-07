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
    
    enum menuTag: Int {
        case pakapo = 0
        case file
        case edit
        case slideshow
        case view
        case window
    }
    
    var preferencesWindowController: NSWindowController?
    
    //Notify
    static let CHANGE_SHOW_PAGE_MODE_NOTIFY = NSNotification.Name(rawValue: "changeShowPageModeNotify")
    
    //Preference
    let FIRST_LAUNCH: String = "firstLaunch"
    static let PAGE_FEED_RIGHT: String = "pageFeedRight"
    static let SEARCH_CHILD_ENABLE: String = "searchChildEnable"
    static let SLIDESHOW_SPEED: String = "slideshowSpeed"
    static let SPECIFIED_DIR: String = "specifiedDir"
    let VIEW_STYLE: String = "viewStyle"
    static let SHOW_PAGE_MODE: String = "showPageMode"
    
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
    var menuMoveSpecifiedDirClosure: (() -> Void)!
    
    //slideshow
    var menuSlideshowClosure: (() -> Void)!
    
    //view
    var menuZoomInClosure: (() -> Void)!
    var menuZoomOutClosure: (() -> Void)!
    var menuResetZoomClosure: (() -> Void)!
    var menuChangeViewStyleClosure: ((_ viewStyle: Int) -> Void)!

    //window
    var menuFullScreenClosure: (() -> Void)!

    // MARK: - appdelegate
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        menuQuitPakapoClosure()
        return NSApplication.TerminateReply.terminateNow
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        initFullScreenMode()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if UserDefaults.standard.string(forKey: FIRST_LAUNCH) == nil {
            initFirstLaunchMenu()
        } else {
            loadMenu()
        }
        
        initNewAddFunction()
    }
    
    func initFirstLaunchMenu() {
        initSameDirectories()
        initOpenRecentDirectories()
        initViewStyle()

        //初期値
        UserDefaults.standard.set(true, forKey: AppDelegate.PAGE_FEED_RIGHT)
        UserDefaults.standard.set(true, forKey: AppDelegate.SEARCH_CHILD_ENABLE)
        UserDefaults.standard.set(nil, forKey: AppDelegate.SPECIFIED_DIR)
        UserDefaults.standard.set(2.0, forKey: AppDelegate.SLIDESHOW_SPEED)
        UserDefaults.standard.set(0, forKey: AppDelegate.SHOW_PAGE_MODE)
        
        UserDefaults.standard.set("finishFirstLaunch", forKey: FIRST_LAUNCH)
    }
    
    func loadMenu() {
        initSameDirectories()
        initOpenRecentDirectories()
        initViewStyle()
    }
    
    func initNewAddFunction() {
        //1.1.1で追加。スライドショウ
        let slideshowSpeed = UserDefaults.standard.float(forKey: AppDelegate.SLIDESHOW_SPEED)
        
        if slideshowSpeed == 0 {
            UserDefaults.standard.set(2.0, forKey: AppDelegate.SLIDESHOW_SPEED)
        }
    }
    
    // MARK: - menu
    func menuWillOpen(_ menu: NSMenu) {
        
        let fileItem: NSMenuItem! = mainMenu.item(withTag: menuTag.file.rawValue)
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
    @IBAction func menuShowPreferencesWindow(_ sender: Any) {
        
        guard let window = NSApplication.shared.mainWindow else {
            return
        }
        
        if window.title == "環境設定" {
            window.close()
            preferencesWindowController = nil
            return
        }
        
        let storyboard: NSStoryboard = NSStoryboard(name: "Pakapo", bundle: nil)
        preferencesWindowController = storyboard.instantiateController(withIdentifier: "PakapoPreferencesWindow") as? NSWindowController
        
        if let preferenceWindow = preferencesWindowController?.window {
            preferencesWindowController?.window?.setFrame(CGRect(x: preferenceWindow.frame.origin.x,
                                                                 y: preferenceWindow.frame.origin.y,
                                                                 width: preferenceWindow.frame.size.width,
                                                                 height: PakapoTabViewController.GENERAL_VIEW_HEIGHT),
                                                          display: true
            )
            
            preferenceWindow.setFrameUsingName("PreferenceWindow")
        }
        preferencesWindowController!.windowFrameAutosaveName = "PreferenceWindow"
        preferencesWindowController!.showWindow(sender)
    }
    
    
    @IBAction func menuQuitApplication(_ sender: Any) {
        menuQuitPakapoClosure()
        NSApplication.shared.terminate(self)
    }
    
    //file
    @IBAction func menuOpenImage(_ sender: NSMenuItem) {
        menuFileOpenClosure()
    }
    
    func initSameDirectories() {
        let fileItem: NSMenuItem! = mainMenu.item(withTag: menuTag.file.rawValue)
        let sameDirectoriesItem: NSMenuItem! = fileItem.submenu?.item(withTag: 2)
        let sameDirectoriesMenu: NSMenu! = sameDirectoriesItem.submenu
        sameDirectoriesMenu.delegate = self
        sameDirectoriesMenu.removeAllItems()
        
        let result = initRootSameDirectoriesClosure()
        
        guard let unwrappedDirectories = result.directories else {
            return
        }
        
        for (index, dir) in unwrappedDirectories.enumerated() {
            let menuItem = NSMenuItem(title: dir.lastPathComponent, action: #selector(pushSameDirectory(_:)), keyEquivalent: "")
            menuItem.tag = index
            sameDirectoriesMenu.addItem(menuItem)
        }
        
        if let unwrappedCurrentIndex = result.currentIndex {
            sameDirectoriesMenu.item(withTag: unwrappedCurrentIndex)?.state = NSControl.StateValue.on
        }
    }
    
    func initOpenRecentDirectories() {
        let fileItem: NSMenuItem! = mainMenu.item(withTag: menuTag.file.rawValue)
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
    
    @IBAction func moveSpecifiedDir(_ sender: Any) {
        menuMoveSpecifiedDirClosure()
    }
    
    //slideshow
    @IBAction func menuSlideshow(_ sender: Any) {
        menuSlideshowClosure()
    }
    
    //view
    @IBAction func menuViewZoomIn(_ sender: Any) {
        menuZoomInClosure()
    }
    
    @IBAction func menuViewZoomOut(_ sender: Any) {
        menuZoomOutClosure()
    }
    
    @IBAction func menuViewResetZoom(_ sender: Any) {
        menuResetZoomClosure()
    }
    
    @IBAction func menuViewStyleDefault(_ sender: Any) {
        selectViewStyle(tag: (sender as! NSMenuItem).tag)
    }
    
    @IBAction func menuViewStyleWidthFit(_ sender: Any) {
        selectViewStyle(tag: (sender as! NSMenuItem).tag)
    }
    
    @IBAction func menuViewStyleOriginalSize(_ sender: Any) {
        selectViewStyle(tag: (sender as! NSMenuItem).tag)
    }
    
    @IBAction func menuViewStyleSpread(_ sender: Any) {
        selectViewStyle(tag: (sender as! NSMenuItem).tag)
    }
    
    func initViewStyle() {
        refreshViewStyle(tag: UserDefaults.standard.integer(forKey: VIEW_STYLE))
    }
    
    func selectViewStyle(tag: Int) {
        
        refreshViewStyle(tag: tag)
        
        UserDefaults.standard.set(tag, forKey: VIEW_STYLE)
        menuChangeViewStyleClosure(tag)
    }
    
    func refreshViewStyle(tag: Int) {
        let viewItem: NSMenuItem! = mainMenu.item(withTag: menuTag.view.rawValue)
        
        for item in viewItem.submenu!.items {
            
            if item.tag != tag {
                item.state = NSControl.StateValue.off
                continue
            }
            
            item.state = NSControl.StateValue.on
        }
    }
    
    //window
    @IBAction func menuToggleFullScreen(_ sender: Any) {
        menuFullScreenClosure()
    }
    
    //help
    @IBAction func menuHelp(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://github.com/gokuge/Pakapo/blob/master/README.md")!)
    }
}

