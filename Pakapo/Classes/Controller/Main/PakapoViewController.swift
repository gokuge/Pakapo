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
    
    var pageText: NSTextField!
    
    var slideshowTimer: Timer?
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        initAppNotification()
    }
    
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
    
    // MARK: - notify
    func initAppNotification() {
        //環境設定でページ表示設定が変更された場合に通知を受け取る
        NotificationCenter.default.addObserver(self, selector: #selector(changeShowPageModeNotify), name: AppDelegate.CHANGE_SHOW_PAGE_MODE_NOTIFY, object: nil)
    }

    @objc func changeShowPageModeNotify() {
        updatePageText()
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
            
            pakapoImageView.getFilesURLClosure = {
                return self.pakapoImageModel.fileContents
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
        
        appDelegate.menuCopyToSpecifiedDirClosure = {
            self.pushCopyToSpecifiedDir()
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
        
        appDelegate.menuToggleTrialReadingModeClosure = {
            self.toggleTrialReadingMode()
        }

        //window
        appDelegate.menuFullScreenClosure = {
            self.pushFullScreenCommand()
        }
        
    }
    
    func setImageView(image: NSImage?) {
        pakapoImageView.setImage(image: image)
        
        view.window?.title = pakapoImageModel.getViewPageTitle()
        
        updatePageText()
    }
    
    func updatePageText() {
        guard let window = view.window else {
            return
        }
        
        let showPageMode = UserDefaults.standard.integer(forKey: AppDelegate.SHOW_PAGE_MODE)
        
        //初期値は右下とする
        let pageTextHeight: CGFloat = 30
        var pageTextY: CGFloat = 0
        var pageTextAlignment: NSTextAlignment = .right
        
        switch showPageMode {
        case 1:
            //左上
            pageTextY = view.frame.size.height - pageTextHeight
            pageTextAlignment = .left
        case 2:
            //右上
            pageTextY = view.frame.size.height - pageTextHeight
        case 3:
            //左下
            pageTextAlignment = .left
        case 4:
            //右下
            break
        default:
            //なし(showPageMode == 0)相当
            pageText.removeFromSuperview()
            pageText = nil
            return
        }

        if pageText == nil {
            pageText = NSTextField()

            pageText.isBordered = false
            pageText.isEditable = false
            pageText.isSelectable = false
            pageText.backgroundColor = NSColor.clear
            window.contentView?.addSubview(pageText)
        }
        
        //現在地と表示中のディレクトリのカウントを取得。存在しなければページ数を出す必要はない
        guard let index = pakapoImageModel.fileContentsIndex,
              let count = pakapoImageModel.fileContents?.count else {
                
            pageText.removeFromSuperview()
            pageText = nil
            return
        }
        
        pageText.stringValue = String(format: "%d/%d", index + 1, count)
        pageText.font = NSFont.systemFont(ofSize: 25)

        //設定画面での変更時や、フルスクリーンモードか否かでwindowのサイズが変わるので常に表示位置を更新
        pageText.alignment = pageTextAlignment
        pageText.frame = CGRect(x: 0, y: pageTextY, width: view.frame.size.width, height: pageTextHeight)


        //保存済みチェック。保存先や現在地が存在しない場合は未保存とみなす
        //未保存はlightGray。保存済みは薄い緑(#a6eda6)
        pageText.textColor = NSColor.lightGray
        if let specifiedDirPath = UserDefaults.standard.url(forKey: AppDelegate.SPECIFIED_DIR),
            let currentDirURL = pakapoImageModel.currentDirURL {
            
            //指定場所の存在チェック
            let fileManager = FileManager.default

            if !fileManager.fileExists(atPath: specifiedDirPath.path) {
                //指定したURLが存在しない
                return
            }
            
            //指定場所 + 現在地のパスで保存済みパスを生成
            let savedDirURL = URL(fileURLWithPath: specifiedDirPath.path + "/" + currentDirURL.lastPathComponent())

            //保存先の存在チェック
            if !fileManager.fileExists(atPath: savedDirURL.path) {
                //未保存
                return
            }
            
            pageText.textColor = NSColor(red: 166/255, green: 237/255, blue: 166/255, alpha: 1)
        }
    }
    
    // MARK: -
    
    /// 指定されたURLでModelの読み込みを開始する
    /// - Parameter url: openPanelやD&Dで開かれたファイル/ディレクトリのURL
    func loadStartingPointImage(url: URL) {
        let result = self.pakapoImageModel.updateRootDirectoryURL(root: url)
        
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
        
        updatePageText()
    }
    
    // MARK: - window
    func openPanel() {
        guard let window = self.view.window else {
            return
        }
        
        let openImagePanel: NSOpenPanel = NSOpenPanel()
        
        if let rootDirPath = pakapoImageModel.getRootDirectoryURL() {
            openImagePanel.directoryURL = rootDirPath
        }

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
        
        updatePageText()
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
        
        //command
        var keyDownCommandKey: Bool = false
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command] {
            keyDownCommandKey = true
        }
        
        //Shift
        var keyDownShiftKey: Bool = false
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.shift] {
            keyDownShiftKey = true
        }
        
        //Alt Option
        var keyDownOptionKey: Bool = false
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.option] {
            keyDownOptionKey = true
        }
        
        switch Int(event.keyCode) {
        case 5:
            //command + g
            if keyDownCommandKey {
                pushSlideshowStart()
            }
        case 8:
            //option + c
            if keyDownOptionKey {
                pushCopyToSpecifiedDir()
            }
        case 51:
            //opthion or shift + delete
            if keyDownOptionKey || keyDownShiftKey {
                pushRemoveToSpecifiedDir()
            }
        case 53:
            pushEsc()
        case 94:
            //shift + _
            if keyDownShiftKey {
                pushCopyToSpecifiedDir()
            }
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
    
    func pushCopyToSpecifiedDir() {
        //指定場所と現在地を取得
        guard let specifiedDirPath = UserDefaults.standard.url(forKey: AppDelegate.SPECIFIED_DIR),
            let currentDirURL = pakapoImageModel.currentDirURL else {
            return
        }
        
        //指定場所の存在チェック
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: specifiedDirPath.path) {
            //指定場所のURLが存在しない
            return
        }
        
        //保存先
        let toDirURL = URL(fileURLWithPath: specifiedDirPath.path + "/" + currentDirURL.lastPathComponent())
        
        do {
            /*
                保存先に既に存在していた場合、エラーとなりcatchに入る
                コピーしようとしているものと、既に存在しているもの、どちらが真なのかは操作者にしかわからない
                コピーしようとしているものを真とし、保存先から一度削除して確実にコピーさせても良いが
                それでは保存済みを示す為にPageTextを色付けしている意味があまりない
             
                ひとまずは削除->上書きではなく、コピー失敗として既に存在しているものを真とする
            */
            try fileManager.copyItem(at: currentDirURL, to: toDirURL)
        } catch {
//            print(error.localizedDescription)
            return
        }

        //指定場所へのコピーが済んだので表示を更新
        updatePageText()
    }
    
    func pushRemoveToSpecifiedDir() {
        //指定場所と現在地を取得
        guard let specifiedDirPath = UserDefaults.standard.url(forKey: AppDelegate.SPECIFIED_DIR),
            let currentDirURL = pakapoImageModel.currentDirURL else {
            return
        }
        
        //指定場所の存在チェック
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: specifiedDirPath.path) {
            //指定場所のURLが存在しない
            return
        }
        
        //指定場所も現在地も取得できたのでコピー
        let toDirURL = URL(fileURLWithPath: specifiedDirPath.path + "/" + currentDirURL.lastPathComponent())

        //保存先の存在チェック
        if fileManager.fileExists(atPath: toDirURL.path) {
            //指定したURLが存在した。削除する
            do {
                try fileManager.removeItem(at: toDirURL)
            } catch {
                return
            }
        }
        
        //指定場所へのコピーが済んだので表示を更新
        updatePageText()
    }
    
    func toggleTrialReadingMode() {
        //試読モードのトグル
        pakapoImageModel.isTrialReadingMode = !pakapoImageModel.isTrialReadingMode
    }
}
