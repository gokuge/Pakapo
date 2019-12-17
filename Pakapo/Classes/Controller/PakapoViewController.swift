//
//  ViewController.swift
//  Pakapo
//
//  Created by gokuge on 2019/12/06.
//  Copyright © 2019 gokuge. All rights reserved.
//

import Cocoa

class PakapoViewController: NSViewController, NSWindowDelegate {
    
    let WINDOW_FULL_SCREEN: String = "windowFullScreen"
    let WINDOW_SCREEN_SIZE: String = "windowScreenSize"
    
    var pakapoImageView: PakapoImageView!
    let pakapoImageModel: PakapoImageModel = PakapoImageModel()
    var isPageFeedRight: Bool!
    var pinchIn: Bool = false
    
    var mouseMovedEndWorkItem: DispatchWorkItem?
    
    // MARK: - init
    override func viewWillAppear() {
        super.viewWillAppear()
        willMakeView()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        makeView()
    }

    func willMakeView() {
        view.window?.delegate = self
    }

    // MARK: - makeView
    func makeView() {
        guard let window = view.window else {
            return
        }

        let appDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
        
        if pakapoImageView == nil {
            pakapoImageView = PakapoImageView(frame: view.frame)
            pakapoImageView.viewStyle = PakapoImageView.ViewStyle(rawValue: UserDefaults.standard.integer(forKey: appDelegate.VIEW_STYLE))!

            pakapoImageView.getFileURLClosure = {
                return self.pakapoImageModel.getFileURL()
            }

            pakapoImageView.getDirURLClosure = {
                return self.pakapoImageModel.currentDirURL
            }
            
            pakapoImageView.dropClosure = {(url: URL) in
                self.selectInitURL(url: url)
            }
                                    
            window.contentView?.addSubview(pakapoImageView)
        }
  
        if let unwrappedURL = pakapoImageModel.loadFileURL(),
           let unwrappedImage: NSImage = pakapoImageModel.loadInitImage(contentURL: unwrappedURL) {
            self.refreshImageView(image: unwrappedImage)
        } else {
            openPanel()
        }
        
        //キー入力有効化
        window.makeFirstResponder(self)
        //マウス移動検知有効化
        window.acceptsMouseMovedEvents = true
        
        makeAppdelegateClosure(appDelegate: appDelegate)
    }
    
    func makeAppdelegateClosure(appDelegate: AppDelegate) {
        
        //init
        appDelegate.initFullScreenMode = {
            if !UserDefaults.standard.bool(forKey: self.WINDOW_FULL_SCREEN) {
                return
            }
            
            guard let window: NSWindow = self.view.window else {
                return
            }
            
            self.fullScreenSizeMode(window: window)
        }
        
        //pakapo
        appDelegate.menuQuitPakapoClosure = {
            self.saveFileURL()
            NSApplication.shared.terminate(self)
        }

        //file
        appDelegate.initRootSameDirectoriesClosure = {
            
            return self.pakapoImageModel.initRootSameDirectories()
        }
        
        appDelegate.menuSameDirectoriesClosure = {(index: Int) -> Void in
            self.refreshImageView(image: self.pakapoImageModel.jumpSameDirectory(index: index))
        }
        
        appDelegate.initOpenRecentDirectoriesClosure = {
            return self.pakapoImageModel.getOpenRecentDirectories()
        }
        
        appDelegate.menuOpenRecentDirectoriesClosure = {(index: Int) -> Void in
            self.refreshImageView(image: self.pakapoImageModel.jumpOpenRecentDirectory(index: index))
        }
        
        appDelegate.menuFileOpenClosure = {
            self.openPanel()
        }
        
        //eidt
        appDelegate.menuCopyOpenClosure = {
            self.pakapoImageView.clickCopyFile()
        }
                
        //setting
        appDelegate.menuPageFeedClosure = {(right: Bool) -> Void in
            self.isPageFeedRight = right
        }

        appDelegate.menuSearchChildEnableClosure = {(enable: Bool) -> Void in
            self.pakapoImageModel.isSearchChild = enable
        }
        
        //view
        appDelegate.menuChangeViewStyleClosure = {(viewStyle: Int) -> Void in
            self.pakapoImageView.viewStyle = PakapoImageView.ViewStyle(rawValue: viewStyle)!
            self.pakapoImageView.resizeFrame(frame: CGRect(x: 0,
                                                           y: 0,
                                                           width: self.view.frame.width,
                                                           height: self.view.frame.height)
            )
        }

        //window
        appDelegate.menuFullScreenClosure = {
            self.pushFullScreenCommand()
        }
        
    }
    
    func refreshImageView(image: NSImage?) {
        pakapoImageView.setImage(image: image)
        
        view.window?.title = pakapoImageModel.loadPageTitle()
    }
    
    // MARK: -
    func openPanel() {
        guard let window = self.view.window else {
            return
        }

        let openImagePanel: NSOpenPanel = NSOpenPanel()

        openImagePanel.allowsMultipleSelection = false
        openImagePanel.canCreateDirectories    = false
        openImagePanel.canChooseDirectories    = true
        openImagePanel.canChooseFiles          = true

        //画像ファイルのみ対象とする
        openImagePanel.allowedFileTypes        = NSImage.imageTypes
        
        openImagePanel.beginSheetModal(for: window, completionHandler: { (response) in
            
            if response != NSApplication.ModalResponse.OK {
                return
            }
            
            guard let unwrappedURL = openImagePanel.url else {
                //存在しないって事は基本無いはず
                return
            }

            self.selectInitURL(url: unwrappedURL)
        })
    }
    
    func selectInitURL(url: URL) {
        let result = self.pakapoImageModel.saveRootDirectoryURL(root: url)
        
        if !result {
            //システムのroot等を選択された場合。あまり考えたくないので無効扱い
            return
        }
        
        self.refreshImageView(image: self.pakapoImageModel.loadInitImage(contentURL: url))
    }
    
    func saveFileURL() {
        pakapoImageModel.saveFileURL()
    }
    
    // MARK: - window delegate
    func windowWillClose(_ notification: Notification) {
        saveFileURL()
    }
    
    func windowDidResize(_ notification: Notification) {
        pakapoImageView.resizeFrame(frame: CGRect(x: 0,
                                                  y: 0,
                                                  width: view.frame.width,
                                                  height: view.frame.height))
    }
    
    // MARK: - window
    func pushFullScreenCommand() {
        guard let window: NSWindow = view.window else {
            return
        }
            
        if window.styleMask.contains(NSWindow.StyleMask.fullScreen) {
            //トグル一発で戻す
//            window.toggleFullScreen(nil)
                
            //cooViewerっぽいフルスクリーンを解除
            defaultWindowSizeMode(window: window)
        } else {
            //トグル一発でFullScreen
//            window.toggleFullScreen(self)

            //自分の意思で切り替えた場合にのみセーブさせる
            //fullScreenSizeModeは起動時にも呼ばれる。フルスクリーン状態で終了していると WINDOW_SCREEN_SIZE に NSScreen.main!.frame がセーブされてしまう為
            UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: WINDOW_SCREEN_SIZE)

            //cooViewerっぽくフルスクリーン
            fullScreenSizeMode(window: window)
        }
    }
    
    func defaultWindowSizeMode(window: NSWindow) {
        //ツールバーのresizeボタン等でtoggleFullScreen(self)でのフルスクリーン状態になっている可能性があるので、強制的にnilへ
        window.toggleFullScreen(nil)
        
        window.styleMask = [NSWindow.StyleMask.borderless,
                            NSWindow.StyleMask.titled,
                            NSWindow.StyleMask.miniaturizable,
                            NSWindow.StyleMask.resizable,
                            NSWindow.StyleMask.closable]

        NSApplication.shared.presentationOptions = NSApplication.PresentationOptions.init()

        window.collectionBehavior = NSWindow.CollectionBehavior.init()
        
        if let unwrappedFrame = UserDefaults.standard.string(forKey: WINDOW_SCREEN_SIZE) {
            window.setFrame(NSRectFromString(unwrappedFrame), display: true)
        }
        
        //非アクティブ時にもwindowを出す
        window.hidesOnDeactivate = false
        
        NSCursor.setHiddenUntilMouseMoves(false)
        
        UserDefaults.standard.set(false, forKey: WINDOW_FULL_SCREEN)
    }
    
    func fullScreenSizeMode(window: NSWindow) {
        window.styleMask = [NSWindow.StyleMask.fullScreen]

        let presentationOptions: NSApplication.PresentationOptions = [NSApplication.PresentationOptions.autoHideDock,
                                                                     NSApplication.PresentationOptions.autoHideMenuBar]
        
        NSApplication.shared.presentationOptions = presentationOptions

        window.collectionBehavior = NSWindow.CollectionBehavior.fullScreenPrimary
        window.setFrame(NSScreen.main!.frame, display: true)
        
        //非アクティブ時にwindowを隠す
        window.hidesOnDeactivate = true
        
        NSCursor.setHiddenUntilMouseMoves(true)
        
        UserDefaults.standard.set(true, forKey: WINDOW_FULL_SCREEN)
    }
    
    // MARK: - key event
    override func keyDown(with event: NSEvent) {
//        print(String(format: "keyCode:%d", event.keyCode))
//        print(String(format: "key:%@", event.charactersIgnoringModifiers!))
        
        switch Int(event.keyCode) {
        case 53:
            pushEsc()
        case 123:
            pushLeftArrow()
        case 124:
            pushRightArrow()
        case 125:
            pushNextDir()
        case 126:
            pushPrevDir()
        default:break
        }

        //複数の修飾キーを取得する場合は[.command]を[.command, .shift]とすれば良い
//        switch event.modifierFlags.intersection(.deviceIndependentFlagsMask) {
//        case [.command] where event.keyCode == 3:
//            pushFullScreenCommand()
//        default:
//            break
//        }
    }
    
    func pushEsc() {
        guard let window: NSWindow = view.window else {
            return
        }
        
        if window.styleMask.contains(NSWindow.StyleMask.fullScreen) {
            defaultWindowSizeMode(window: window)
        }
    }
    
    func pushRightArrow() {
        if isPageFeedRight {
            pushNextPage()
        } else {
            pushPrevPage()
        }
    }
    
    func pushLeftArrow() {
        if isPageFeedRight {
            pushPrevPage()
        } else {
            pushNextPage()
        }
    }

    func pushNextPage() {
        refreshImageView(image: pakapoImageModel.loadNextImage())
    }

    func pushPrevPage() {
        refreshImageView(image: pakapoImageModel.loadPrevImage())
    }
    
    func pushNextDir() {
        refreshImageView(image: pakapoImageModel.loadNextDirectory())
    }
    
    func pushPrevDir() {
        refreshImageView(image: pakapoImageModel.loadPrevDirectory())
    }
    
    // MARK: - mouse
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        switch event.modifierFlags.intersection(.deviceIndependentFlagsMask) {
        case [.control]:
            //Control+マウスクリックの場合は右クリックを押されたものとする
            pakapoImageView.showContextMenu(event: event)
            return
        default:
            break
        }
        
        if (view.frame.width / 2) < event.locationInWindow.x {
            pushRightArrow()
        } else {
            pushLeftArrow()
        }
        
    }
    
    override func mouseMoved(with event: NSEvent) {
        //マウス位置がviewの範囲外だった場合は何もしない
        if !view.frame.contains(event.locationInWindow) {
            return
        }
        
        super.mouseMoved(with: event)
        
        if let unwrappedMouseMovedEndWorkItem = mouseMovedEndWorkItem {
            unwrappedMouseMovedEndWorkItem.cancel()
        }
        
        mouseMovedEndWorkItem = DispatchWorkItem {
            self.autoHideMouseCursor()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: mouseMovedEndWorkItem!)
    }
    
    func autoHideMouseCursor() {
        guard let window: NSWindow = view.window else {
            return
        }
        if window.styleMask.contains(NSWindow.StyleMask.fullScreen) {
            NSCursor.setHiddenUntilMouseMoves(true)
        }
    }
    
    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        if event.deltaY > 0 {
            pushLeftArrow()
        } else if event.deltaY < 0 {
            pushRightArrow()
        }
    }
    
    
    override func magnify(with event: NSEvent) {
        
        //ピンチの終了時はmagnificationが0で来るので、「イン/アウト」のどちらで終えたのかがわからない。直前までのを記憶する必要がある
        if event.magnification > 0 {
            pinchIn = false
        } else if event.magnification < 0{
            pinchIn = true
        }
        
        //終了時以外は更新させない
        if event.phase.rawValue != NSEvent.Phase.ended.rawValue {
            return
        }
        
        //cooViewerのピンチは0,1,3,2の順
        var viewStyle: Int = pakapoImageView.viewStyle.rawValue
        if pinchIn {
            if viewStyle == PakapoImageView.ViewStyle.defaultView.rawValue {
                return
            }
            viewStyle -= 1
        } else {
            if viewStyle == PakapoImageView.ViewStyle.originalSizeView.rawValue {
                return
            }
            viewStyle += 1
        }
        let appDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.selectViewStyle(tag: viewStyle)
    }
}

