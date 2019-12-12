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
        
        if pakapoImageView == nil {
            pakapoImageView = PakapoImageView(frame: view.frame)
            
            pakapoImageView.getFileURLClosure = {
                return self.pakapoImageModel.getFileURL()
            }

            pakapoImageView.getDirURLClosure = {
                return self.pakapoImageModel.currentDirURL
            }
                        
            view.window?.contentView?.addSubview(pakapoImageView)
        }
  
        if let unwrappedURL = pakapoImageModel.loadFileURL(),
           let unwrappedImage: NSImage = pakapoImageModel.loadInitImage(contentURL: unwrappedURL) {
            self.refreshImageView(image: unwrappedImage)
        } else {
            openPanel()
        }
        
        //キー入力有効化
        window.makeFirstResponder(self)
        
        makeAppdelegateClosure()
    }
    
    func makeAppdelegateClosure() {
        let appdelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
        
        //init
        appdelegate.initFullScreenMode = {
            if !UserDefaults.standard.bool(forKey: self.WINDOW_FULL_SCREEN) {
                return
            }
            
            guard let window: NSWindow = self.view.window else {
                return
            }
            
            self.fullScreenSizeMode(window: window)
        }
        
        //pakapo
        appdelegate.menuQuitPakapoClosure = {
            self.saveFileURL()
            NSApplication.shared.terminate(self)
        }

        //file
        appdelegate.initRootSameDirectoriesClosure = {
            
            return self.pakapoImageModel.initRootSameDirectories()
        }
        
        appdelegate.menuSameDirectoriesClosure = {(index: Int) -> Void in
            self.refreshImageView(image: self.pakapoImageModel.jumpSameDirectory(index: index))
        }
        
        appdelegate.menuFileOpenClosure = {
            self.openPanel()
        }
        
        //eidt
        appdelegate.menuCopyOpenClosure = {
            self.pakapoImageView.clickCopyFile()
        }
                
        //view
        appdelegate.menuPageFeedClosure = {(right: Bool) -> Void in
            self.isPageFeedRight = right
        }

        appdelegate.menuSearchChildEnableClosure = {(enable: Bool) -> Void in
            self.pakapoImageModel.isSearchChild = enable
        }

        //window
        appdelegate.menuFullScreenClosure = {
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

            let result = self.pakapoImageModel.saveRootDirectoryURL(root: unwrappedURL)
            
            if !result {
                //システムのroot等を選択された場合。あまり考えたくないので無効扱い
                return
            }
            
            self.refreshImageView(image: self.pakapoImageModel.loadInitImage(contentURL: unwrappedURL))
        })
    }
    
    func saveFileURL() {
        pakapoImageModel.saveFileURL()
    }
    
    // MARK: - window delegate
    func windowWillClose(_ notification: Notification) {
        saveFileURL()
    }
    
    func windowDidResize(_ notification: Notification) {
        guard let frame = self.view.window?.frame else {
            return
        }

        pakapoImageView.resizeFrame(frame: CGRect(x: 0,
                                                  y: 0,
                                                  width: frame.width,
                                                  height: frame.height))
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
        
        UserDefaults.standard.set(true, forKey: WINDOW_FULL_SCREEN)
    }
    
    // MARK: - key event
    override func keyDown(with event: NSEvent) {
        print(String(format: "keyCode:%d", event.keyCode))
        print(String(format: "key:%@", event.charactersIgnoringModifiers!))
        
        switch Int(event.keyCode) {
        case 53:
            print("esc")
            pushEsc()
        case 123:
            print("left")
            pushLeftArrow()
        case 124:
            print("right")
            pushRightArrow()
        case 125:
            print("down")
            pushNextDir()
        case 126:
            print("up")
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
        guard let window: NSWindow = view.window else {
            return
        }
        
        if (window.frame.width / 2) < event.locationInWindow.x {
            pushRightArrow()
        } else {
            pushLeftArrow()
        }
        
    }    
}

