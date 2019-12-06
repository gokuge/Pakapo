//
//  ViewController.swift
//  Pakapo
//
//  Created by gokuge on 2019/12/06.
//  Copyright © 2019 gokuge. All rights reserved.
//

import Cocoa

class PakapoViewController: NSViewController {
    
    let WINDOW_FULL_SCREEN: String = "windowFullScreen"
    
    var pakapoImageView: PakapoImageView!
    let pakapoImageModel: PakapoImageModel = PakapoImageModel()
    
    
    // MARK: - makeView
    override func viewWillAppear() {
        super.viewWillAppear()
        willMakeView()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        makeView()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        saveFileURL()
    }

    func willMakeView() {
        //ウィンドウサイズ変更検知
        NotificationCenter.default.addObserver(self, selector: #selector(windowResize), name: NSWindow.didResizeNotification, object: nil)
    }

    func makeView() {
        
        guard let window = self.view.window else {
            return
        }
        
        if pakapoImageView == nil {
            pakapoImageView = PakapoImageView(frame: self.view.frame)
            
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
        
        //キー入力
        window.makeFirstResponder(self)
        
        makeAppdelegateClosure()
    }
    
    func makeAppdelegateClosure() {
        let appdelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
        
        appdelegate.initFullScreenMode = {
            if UserDefaults.standard.bool(forKey: self.WINDOW_FULL_SCREEN) {
                self.pushFullScreenCommand()
            }
        }

        appdelegate.menuFileOpenClosure = {
            self.openPanel()
        }
        
        appdelegate.menuQuitPakapoClosure = {
            self.saveFileURL()
            NSApplication.shared.terminate(self)
        }
    }
    
    func refreshImageView(image: NSImage?) {
        
        pakapoImageView.setImage(image: image)
        
        view.window?.title = pakapoImageModel.loadPageTitle()
    }
    
    // MARK: -
    @objc func windowResize() {
        
        guard let frame = self.view.window?.frame else {
            return
        }

        pakapoImageView.resizeFrame(frame: CGRect(x: 0,
                                                  y: 0,
                                                  width: frame.width,
                                                  height: frame.height))
    }
    
    func openPanel() {
        
        guard let window = self.view.window else {
            return
        }

        //NSOpenPanel()、beginSheetModalの実行時にNSWindow.didResizeNotificationが発行され、windowResizeが呼ばれてしまうので一旦登録を削除
        NotificationCenter.default.removeObserver(self)
        let openImagePanel: NSOpenPanel = NSOpenPanel()

        openImagePanel.allowsMultipleSelection = false
        openImagePanel.canCreateDirectories    = false
        openImagePanel.canChooseDirectories    = true
        openImagePanel.canChooseFiles          = true

        //画像ファイルのみ対象とする
        openImagePanel.allowedFileTypes        = NSImage.imageTypes
        
        openImagePanel.beginSheetModal(for: window, completionHandler: { (response) in
            
            //リサイズのNotification再登録
            NotificationCenter.default.addObserver(self, selector: #selector(self.windowResize), name: NSWindow.didResizeNotification, object: nil)
            
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
    
    // MARK: - key event
    override func keyDown(with event: NSEvent) {
        print(String(format: "keyCode:%d", event.keyCode))
        print(String(format: "key:%@", event.charactersIgnoringModifiers!))
        
        switch Int(event.keyCode) {
        case 123:
            print("left")
            pushPrevPage()
        case 124:
            print("right")
            pushNextPage()
        case 125:
            print("down")
            pushNextDir()
        case 126:
            print("up")
            pushPrevDir()
        default:break
        }

        //複数の修飾キーを取得する場合は[.command]を[.command, .shift]とすれば良い
        switch event.modifierFlags.intersection(.deviceIndependentFlagsMask) {
        case [.command] where event.keyCode == 3:
            pushFullScreenCommand()
        default:
            break
        }
    }

    func pushNextPage() {
        refreshImageView(image: pakapoImageModel.loadNextImage())
    }

    func pushPrevPage() {
        refreshImageView(image: pakapoImageModel.loadPrevImage())
    }
    
    func pushNextDir() {
        refreshImageView(image: pakapoImageModel.loadNextDir())
    }
    
    func pushPrevDir() {
        refreshImageView(image: pakapoImageModel.loadPrevDir())
    }
    
    func pushFullScreenCommand() {
        guard let window: NSWindow = view.window else {
            return
        }
        
        if window.styleMask.contains(.fullScreen) {
            //フルスクリーン状態なので解除する
            window.toggleFullScreen(nil)
            UserDefaults.standard.set(false, forKey: WINDOW_FULL_SCREEN)
        } else {
            //フルスクリーン状態へ
            window.toggleFullScreen(self)
            UserDefaults.standard.set(true, forKey: WINDOW_FULL_SCREEN)
        }
    }
}

