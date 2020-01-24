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
    
    var slideshowTimer: Timer?
    
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
                return self.pakapoImageModel.getViewPageURL()
            }

            pakapoImageView.getDirURLClosure = {
                return self.pakapoImageModel.currentDirURL
            }

            pakapoImageView.leftClickClosure = {
                self.pushLeftArrow()
            }
            
            pakapoImageView.rightClickClosure = {
                self.pushRightArrow()
            }
            
            pakapoImageView.changeViewStyleClosure = {(viewStyle: Int) in
                appDelegate.selectViewStyle(tag: viewStyle)
            }

            pakapoImageView.dropClosure = {(url: URL) in
                self.loadStartingPointImage(url: url)
            }
                                    
            window.contentView?.addSubview(pakapoImageView)
        }
  
        if let unwrappedURL = pakapoImageModel.loadLastViewPageURL(),
           let unwrappedImage = pakapoImageModel.getStartingPointImage(contentURL: unwrappedURL) {
            self.setImageView(image: unwrappedImage)
        } else {
            openPanel()
        }
        
        //キー入力有効化
        window.makeFirstResponder(self)
        
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
            self.saveLastViewPageURL()
        }

        //file
        appDelegate.initRootSameDirectoriesClosure = {
            
            return self.pakapoImageModel.makeRootSameDirectories()
        }
        
        appDelegate.menuSameDirectoriesClosure = {(index: Int) -> Void in
            self.setImageView(image: self.pakapoImageModel.jumpSameDirectory(index: index))
        }
        
        appDelegate.initOpenRecentDirectoriesClosure = {
            return self.pakapoImageModel.getOpenRecentDirectories()
        }
        
        appDelegate.menuOpenRecentDirectoriesClosure = {(index: Int) -> Void in
            self.setImageView(image: self.pakapoImageModel.jumpOpenRecentDirectory(index: index))
        }
        
        appDelegate.menuFileOpenClosure = {
            self.openPanel()
        }
        
        //eidt
        appDelegate.menuCopyOpenClosure = {
            self.pakapoImageView.clickCopyFile()
        }
        
        //slideshow
        appDelegate.menuSlideshowClosure = {
            self.pushSlideshowStart()
        }
        
        //view
        appDelegate.menuZoomInClosure = {
            //通常のスクロールでのズームの10倍
            self.pakapoImageView.zoom(rate: 12.0)
        }
        
        appDelegate.menuZoomOutClosure = {
            self.pakapoImageView.zoom(rate: -12.0)
        }
        
        appDelegate.menuResetZoomClosure = {
            self.pakapoImageView.resetZoom()
        }
        
        appDelegate.menuChangeViewStyleClosure = {(viewStyle: Int) -> Void in
            self.pakapoImageView.resizeFrame(frame: CGRect(x: 0,
                                                           y: 0,
                                                           width: self.view.frame.width,
                                                           height: self.view.frame.height),
                                             changeStyle: PakapoImageView.ViewStyle(rawValue: viewStyle)!
            )
        }

        //window
        appDelegate.menuFullScreenClosure = {
            self.pushFullScreenCommand()
        }
        
    }
    
    func setImageView(image: NSImage?) {
        pakapoImageView.setImage(image: image)
        
        view.window?.title = pakapoImageModel.getViewPageTitle()
    }
    
    // MARK: -
    
    /// 指定されたURLでModelの読み込みを開始する
    /// - Parameter url: openPanelやD&Dで開かれたファイル/ディレクトリのURL
    func loadStartingPointImage(url: URL) {
        let result = self.pakapoImageModel.saveRootDirectoryURL(root: url)
        
        if !result {
            //システムのroot等を選択された場合。あまり考えたくないので無効扱い
            return
        }
        
        self.setImageView(image: self.pakapoImageModel.getStartingPointImage(contentURL: url))
    }
    
    /// 終了時の表示中のURL保存をModelにわたす
    func saveLastViewPageURL() {
        pakapoImageModel.saveLastViewPageURL()
    }
}

extension PakapoViewController {
    // MARK: - window delegate
    func windowWillClose(_ notification: Notification) {
        saveLastViewPageURL()
    }
    
    func windowDidResize(_ notification: Notification) {
        pakapoImageView.resizeFrame(frame: CGRect(x: 0,
                                                  y: 0,
                                                  width: view.frame.width,
                                                  height: view.frame.height),
                                    changeStyle: nil
        )
    }
    
    // MARK: - window
    func openPanel() {
        guard let window = self.view.window else {
            return
        }

        let openImagePanel: NSOpenPanel = NSOpenPanel()

        openImagePanel.allowsMultipleSelection = false
        openImagePanel.canCreateDirectories    = false
        openImagePanel.canChooseDirectories    = true
        openImagePanel.canChooseFiles          = true

        //読み込み可能なファイルのみ対象とする(画像 + zip)
        openImagePanel.allowedFileTypes        = NSImage.imageTypes + ["zip"]
        
        openImagePanel.beginSheetModal(for: window, completionHandler: { (response) in
            
            if response != NSApplication.ModalResponse.OK {
                return
            }
            
            guard let unwrappedURL = openImagePanel.url else {
                return
            }

            self.loadStartingPointImage(url: unwrappedURL)
        })
    }
    
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
}

extension PakapoViewController {
    // MARK: - key event
    override func keyDown(with event: NSEvent) {
//        print(String(format: "keyCode:%d", event.keyCode))
//        print(String(format: "key:%@", event.charactersIgnoringModifiers!))
        
        switch Int(event.keyCode) {
        case 5:
            //g
            pushSlideshowStart()
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
        if UserDefaults.standard.bool(forKey: AppDelegate.PAGE_FEED_RIGHT) {
            pushNextPage()
        } else {
            pushPrevPage()
        }
    }
    
    func pushLeftArrow() {
        if UserDefaults.standard.bool(forKey: AppDelegate.PAGE_FEED_RIGHT) {
            pushPrevPage()
        } else {
            pushNextPage()
        }
    }

    func pushNextPage() {
        setImageView(image: pakapoImageModel.getNextImage())
    }

    func pushPrevPage() {
        setImageView(image: pakapoImageModel.getPrevImage())
    }
    
    func pushNextDir() {
        setImageView(image: pakapoImageModel.getNextDirectoryImage())
    }
    
    func pushPrevDir() {
        setImageView(image: pakapoImageModel.getPrevDirectoryImage())
    }
    
    func pushSlideshowStart() {
        if let unwrappedSlideshowTimer = slideshowTimer {
            unwrappedSlideshowTimer.invalidate()
            slideshowTimer = nil
            return
        }
        
        let interval: TimeInterval = TimeInterval(UserDefaults.standard.float(forKey: AppDelegate.SLIDESHOW_SPEED))
        
        slideshowTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { _ in
            self.pushNextPage()
        })

        self.pushNextPage()
    }
}
