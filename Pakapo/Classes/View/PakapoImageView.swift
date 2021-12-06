//
//  PakapoImageView.swift
//  Pakapo
//
//  Created by gokuge on 2019/12/06.
//  Copyright © 2019 gokuge. All rights reserved.
//

import Cocoa

class PakapoImageView: NSView {
    
    let SPREAD_WIDTH: CGFloat = 740
    
    enum ViewStyle: Int {
        case defaultView = 0
        case widthFitView
        case spreadView
        case originalSizeView
    }
    
    var getFileURLClosure:(() -> URL?)!
    var getFilesURLClosure:(() -> [URL]?)!
    var getDirURLClosure:(() -> URL?)!
    var leftClickClosure:(() -> Void)!
    var rightClickClosure:(() -> Void)!
    var changeViewStyleClosure:((Int) -> Void)!
    var dropClosure:((URL) -> Void)!

    var viewStyle: ViewStyle = ViewStyle.defaultView

    let imageView: NSImageView = NSImageView()
    let imageClipView: PakapoImageClipView = PakapoImageClipView()
    let imageScrollView: PakapoImageScrollView = PakapoImageScrollView()
    var draggingView: DraggingView!
    var warningText: NSTextField?
    
    var scrolling: Bool = false
    
    var mouseMovedEndWorkItem: DispatchWorkItem?
    var scrollEndWorkItem: DispatchWorkItem?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        imageView.frame = frameRect
        imageView.wantsLayer = true
        imageView.imageScaling = NSImageScaling.scaleProportionallyUpOrDown
        
//        imageView.layer?.backgroundColor = NSColor.red.cgColor
        
        if viewStyle.rawValue == ViewStyle.originalSizeView.rawValue {
            imageView.imageScaling = NSImageScaling.scaleNone
        }

        draggingView = DraggingView(frame: frameRect)
        draggingView.dropClosure = { (url: URL) in
            self.dropClosure(url)
        }

        imageClipView.backgroundColor = NSColor.black

        imageScrollView.frame = frameRect
        imageScrollView.backgroundColor = NSColor.black
        imageScrollView.contentView = imageClipView
        imageScrollView.documentView = imageView
        imageScrollView.hasHorizontalScroller = true
        imageScrollView.hasVerticalScroller = true
        imageScrollView.autohidesScrollers = true
        imageScrollView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(scrollEvent(_:)), name: NSView.boundsDidChangeNotification, object: imageScrollView.contentView)
                
        imageScrollView.canScrollClosure = {
            
            //画面内に収める以外は常にスクロール
            if self.viewStyle != ViewStyle.defaultView {
                return true
            }
            
            //画面内に収める表示形式で、ズームしていない場合はページ送り
            if self.frame.width == self.imageView.frame.width && self.frame.height == self.imageView.frame.height {
                return false
            }
                        
            return true
        }
        addSubview(imageScrollView)
        addSubview(draggingView)
    }
    
    /// scrollViewの状態変更(スクロール時も同様)検知時に呼ばれる
    @objc func scrollEvent(_ notification: NSNotification) {
        scrolling = true
        
        if let unwrappedScrollEndWorkItem = scrollEndWorkItem {
            unwrappedScrollEndWorkItem.cancel()
        }
        
        scrollEndWorkItem = DispatchWorkItem {
            self.scrolling = false
        }

        //惰性スクロールが結構残ってる可能性があるので1.5とする。完全に終了した事をイベントで取得出来れば良いのだけど、結構悩ましい
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: scrollEndWorkItem!)
    }
    
    /// ImageViewに画像をセットする
    /// - Parameters:
    ///   - image: 表示しようとしているファイル
    func setImage(image: NSImage?) {
        
        guard let unwrappedImage = image else {
            displayNoImage()
            return
        }
        
        if let unwrappedWarningText = warningText {
            unwrappedWarningText.removeFromSuperview()
            warningText = nil
        }
        
        imageView.image = unwrappedImage
        
        initDocumentViewSize(image: unwrappedImage)
    }
    
    /// PakapoImageViewと扱うviewのサイズを変更する
    /// - Parameters:
    ///   - frame: この引数のサイズになるように諸々のviewを更新させる
    ///   - changeStyle: 表示形式。変更する場合のみ値が入る
    func resizeFrame(frame: CGRect, changeStyle: ViewStyle?) {
        let point: NSPoint = NSPoint(x: imageScrollView.contentView.documentVisibleRect.origin.x,
                                     y: imageScrollView.contentView.documentVisibleRect.origin.y)
        
        let oldViewRect: NSRect = self.frame
        let oldImageViewRect: NSRect = imageView.frame

        self.frame = frame
        draggingView.frame = frame
        imageView.frame = frame
        imageScrollView.frame = frame
        
        guard let unwrappedImage = imageView.image else {
            resizeWarningTextView()
            return
        }
        
        if let unwrappedChangeViewStyle = changeStyle {
            viewStyle = unwrappedChangeViewStyle
            initDocumentViewSize(image: unwrappedImage)
        } else {
            let diffW: CGFloat = frame.width - oldViewRect.width
            let diffH: CGFloat = frame.height - oldViewRect.height
            imageView.frame = CGRect(x: imageView.frame.origin.x,
                                     y: imageView.frame.origin.y,
                                     width: oldImageViewRect.width + diffW,
                                     height: oldImageViewRect.height + diffH)
        }
        
        imageScrollView.documentView?.scroll(point)
    }
    
    /// 警告ビューで表示する文字を適切なフォントサイズに変更する
    func resizeWarningTextView() {
        guard let unwrappedWarningText = warningText else {
            return
        }
        
        let height: CGFloat = frame.height / 3
        
        unwrappedWarningText.frame = CGRect(x: 0, y: (frame.height / 2) - (height / 2), width: frame.width, height: height)
        
        let fontSize: CGFloat = (2.0 * (height - 1.0278) / 1.177).rounded() / 2.0
        unwrappedWarningText.font = NSFont.systemFont(ofSize: fontSize)
    }
    
    /// 表示形式で指定された通りにdocumentViewを初期化する
    /// - Parameters:
    ///   - image: 表示しようとしているファイル。サイズの取得に使う
    func initDocumentViewSize(image: NSImage) {
        let imageRep: NSBitmapImageRep  = NSBitmapImageRep(data: image.tiffRepresentation!)!
        let pixelW: CGFloat = CGFloat(imageRep.pixelsWide)
        let pixelH: CGFloat = CGFloat(imageRep.pixelsHigh)
        let ratio: CGFloat = frame.width / pixelW
        
        var resizeW: CGFloat = 0
        var resizeh: CGFloat = 0
        
        switch viewStyle.rawValue {
        case ViewStyle.defaultView.rawValue:
            resizeW = frame.width
            resizeh = frame.height
        case ViewStyle.widthFitView.rawValue:
            resizeW = pixelW * ratio
            resizeh = pixelH * ratio
        case ViewStyle.spreadView.rawValue:
            //初期値は横フィット
            resizeW = pixelW * ratio
            resizeh = pixelH * ratio
            
            if (pixelW > SPREAD_WIDTH){
                //既定値より大きい場合にのみ見開き設定(横2倍フィット)
                resizeW *= 2
                resizeh *= 2
            }
            
        case ViewStyle.originalSizeView.rawValue:
            resizeW = pixelW
            resizeh = pixelH
        default:
            break
        }
        
        //どちらかViewのsizeより小さかった場合はdefaultViewと同じ表示状態にする
        if (resizeW < frame.width) {
            resizeW = frame.width
        }
        
        if (resizeh < frame.height) {
            resizeh = frame.height
        }
        
        imageScrollView.documentView?.frame = CGRect(x: 0.0,
                                                y: 0.0,
                                                width: resizeW,
                                                height: resizeh
        )

    }
    
    /// 表示されているImageViewを拡大縮小する。ウィンドウで表示されている領域の中心に向かって拡大する
    /// - Parameters:
    ///   - rate: 拡大縮小率
    func zoom(rate: CGFloat) {
        if rate == 0 {
            return
        }
        
        let oldScrollPoint: NSPoint = NSPoint(x: self.imageScrollView.contentView.documentVisibleRect.origin.x,
                                              y: self.imageScrollView.contentView.documentVisibleRect.origin.y)
        
        let oldSize = imageScrollView.documentView!.frame
        
        //rateそのままだと拡大縮小率として小さすぎるので*10する
        let zoomW = imageScrollView.documentView!.frame.width + (10 * rate)
        let zoomH = imageScrollView.documentView!.frame.height + (10 * rate)
        
        if zoomW <= frame.width || zoomH <= frame.height {
            if let unwrappedImage = imageView.image {
                initDocumentViewSize(image: unwrappedImage)
            }
            return
        }

        imageClipView.isZooming = true
        imageScrollView.documentView!.frame = CGRect(x: 0,
                                                y: 0,
                                                width: zoomW,
                                                height: zoomH)
        imageClipView.isZooming = false
        
        let zoomDiffSize = NSSize(width: imageScrollView.documentView!.frame.width - oldSize.width,
                              height: imageScrollView.documentView!.frame.height - oldSize.height)
        
        let point: NSPoint = NSPoint(x: oldScrollPoint.x + (zoomDiffSize.width / 2),
                                     y: oldScrollPoint.y + (zoomDiffSize.height / 2))

        imageScrollView.documentView?.scroll(point)
    }
    
    /// 拡大縮小率のリセット。現状のviewStyleを指定する事でdocumentViewが初期化される
    func resetZoom() {
        resizeFrame(frame: frame, changeStyle: viewStyle)
    }
    
    func displayNoImage() {
        imageView.image = nil
        
        guard let unwrappedWarningText = warningText else {
            warningText = NSTextField()
            warningText!.stringValue = "NO IMAGE"
            warningText!.alignment = NSTextAlignment.center
            warningText!.isBordered = false
            warningText!.isEditable = false
            warningText!.isSelectable = false
            
            warningText!.textColor = NSColor.lightGray
            warningText!.backgroundColor = NSColor.clear
            
            resizeWarningTextView()
            
            addSubview(warningText!)
            addSubview(draggingView)
            return
        }
        
        addSubview(unwrappedWarningText)
        addSubview(draggingView)
    }
}

extension PakapoImageView {
    // MARK: - mouse event
    /// マウス検知領域を設定。ウィンドウ内のみにする
    override func updateTrackingAreas() {
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow]
        addTrackingArea(NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil))
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        switch event.modifierFlags.intersection(.deviceIndependentFlagsMask) {
        case [.control]:
            //Control+マウスクリックの場合は右クリックを押されたものとする
            showContextMenu(event: event)
            return
        default:
            break
        }
        
        if (frame.width / 2) < event.locationInWindow.x {
            rightClickClosure()
        } else {
            leftClickClosure()
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
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
        guard let unwrappedWindow: NSWindow = window else {
            return
        }
        if unwrappedWindow.styleMask.contains(NSWindow.StyleMask.fullScreen) {
            NSCursor.setHiddenUntilMouseMoves(true)
        }
    }
    
    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        switch event.modifierFlags.intersection(.deviceIndependentFlagsMask) {
        case [.control]:
            zoom(rate: event.deltaY)

            return
        default:
            break
        }
        
        //スクロール中ではページ送りさせない
        if scrolling {
            return
        }
        
        if event.deltaY > 0 {
            leftClickClosure()
        } else if event.deltaY < 0 {
            rightClickClosure()
        }
    }
    
    override func magnify(with event: NSEvent) {
        zoom(rate: event.magnification * 100)
    }
    
    ///右クリック検知でシステムから来るイベント
    override func menu(for event: NSEvent) -> NSMenu? {
        return makeContextMenu()
    }
    
    ///ctrl + 左クリック用。viewController側から呼ばれる
    func showContextMenu(event: NSEvent) {
        NSMenu.popUpContextMenu(makeContextMenu(), with: event, for: self)
    }
    
    func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "ファイルを表示する", action: #selector(clickShowFile), keyEquivalent: "")
        menu.addItem(withTitle: "ファイルをコピーする", action: #selector(clickCopyFile), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "フォルダを表示する", action: #selector(clickShowDir), keyEquivalent: "")
        menu.addItem(withTitle: "フォルダをコピーする", action: #selector(clickCopyDir), keyEquivalent: "")
        
        return menu
    }

    @objc func clickShowFile() {
        guard let unwrappedFileURL = getFileURLClosure() else {
            return
        }
        
        guard let unwrappedCurrentDirURL = getDirURLClosure() else {
            return
        }

        NSWorkspace.shared.selectFile(unwrappedFileURL.path, inFileViewerRootedAtPath: unwrappedCurrentDirURL.path)
    }
    
    @objc func clickCopyFile() {
        guard let unwrappedFileURL = getFileURLClosure() else {
            return
        }
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([unwrappedFileURL as NSPasteboardWriting])
    }
    
    @objc func clickMoveSpecifiedDirClosure() {
        //指定場所と現在地を取得
        guard let specifiedDirPath = UserDefaults.standard.url(forKey: AppDelegate.SPECIFIED_DIR),
            let currentDirURL = getDirURLClosure(),
            let currentFiles = getFilesURLClosure() else {
            return
        }
        
        //指定場所の存在チェック
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: specifiedDirPath.path) {
            //指定したURLが存在しない
            return
        }
        
        //指定場所も現在地も取得できたのでコピー
        let toDirURL = URL(fileURLWithPath: specifiedDirPath.path + "/" + currentDirURL.lastPathComponent())

        //保存先の存在チェック
        if fileManager.fileExists(atPath: toDirURL.path) {
            //指定したURLが存在した。一旦それを削除する
            do {
                try fileManager.removeItem(at: toDirURL)
            } catch {
                return
            }
        }
        
        //保存先にDirectoryを作成
        do {
            try fileManager.createDirectory(at: toDirURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return
        }

        //Directory作成後にファイルをコピー
        for fromFileURL in currentFiles {
            let toFileURL = URL(fileURLWithPath: toDirURL.path + "/" + fromFileURL.lastPathComponent())
            do {
                try fileManager.copyItem(at: fromFileURL, to: toFileURL)
            } catch {
                return
            }
        }
    }

    @objc func clickShowDir() {
        guard let unwrappedCurrentDirURL = getDirURLClosure() else {
            return
        }
        
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: unwrappedCurrentDirURL.path)
    }
    
    @objc func clickCopyDir() {
        guard let unwrappedCurrentDirURL = getDirURLClosure() else {
            return
        }
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([unwrappedCurrentDirURL as NSPasteboardWriting])
    }
}
