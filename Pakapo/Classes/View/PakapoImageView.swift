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
    var getDirURLClosure:(() -> URL?)!
    var leftClickClosure:(() -> Void)!
    var rightClickClosure:(() -> Void)!
    var changeViewStyleClosure:((Int) -> Void)!
    var dropClosure:((URL) -> Void)!

    var viewStyle: ViewStyle = ViewStyle.defaultView

    var imageURL: URL?
    let imageView: NSImageView = NSImageView()
    let imageClipView: PakapoImageClipView = PakapoImageClipView()
    let scrollView: PakapoImageScrollView = PakapoImageScrollView()
    var draggingView: DraggingView!
    var warningText: NSTextField?
    
    var pinchIn: Bool = false
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
        
        scrollView.frame = frameRect
        scrollView.backgroundColor = NSColor.black
        imageClipView.backgroundColor = NSColor.black
        scrollView.contentView = imageClipView
        scrollView.documentView = imageView
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(didScroll(_:)), name: NSView.boundsDidChangeNotification, object: scrollView.contentView)
                
        scrollView.canScrollClosure = {
            
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
        addSubview(scrollView)
        addSubview(draggingView)
    }
    
    @objc func didScroll(_ notification: NSNotification) {
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
    
    func resizeFrame(frame: CGRect, changeStyle: ViewStyle?) {
        let point: NSPoint = NSPoint(x: scrollView.contentView.documentVisibleRect.origin.x,
                                     y: scrollView.contentView.documentVisibleRect.origin.y)
        
        let oldViewRect: NSRect = self.frame
        let oldImageViewRect: NSRect = imageView.frame

        self.frame = frame
        draggingView.frame = frame
        imageView.frame = frame
        scrollView.frame = frame
        
        guard let unwrappedImage = imageView.image else {
            resizeWarningTextView()
            return
        }
        
        if let unwrappedChangeViewStyle = changeStyle {
            viewStyle = unwrappedChangeViewStyle
            resizeDocumentView(image: unwrappedImage)
        } else {
            let diffW: CGFloat = frame.width - oldViewRect.width
            let diffH: CGFloat = frame.height - oldViewRect.height
            imageView.frame = CGRect(x: imageView.frame.origin.x,
                                     y: imageView.frame.origin.y,
                                     width: oldImageViewRect.width + diffW,
                                     height: oldImageViewRect.height + diffH)
        }
        
        scrollView.documentView?.scroll(point)
    }
    
    func resizeDocumentView(image: NSImage) {
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
        
        scrollView.documentView?.frame = CGRect(x: 0.0,
                                                y: 0.0,
                                                width: resizeW,
                                                height: resizeh
        )

    }
    
    func resizeWarningTextView() {
        guard let unwrappedWarningText = warningText else {
            return
        }
        
        let height: CGFloat = frame.height / 3
        
        unwrappedWarningText.frame = CGRect(x: 0, y: (frame.height / 2) - (height / 2), width: frame.width, height: height)
        
        let fontSize: CGFloat = (2.0 * (height - 1.0278) / 1.177).rounded() / 2.0
        unwrappedWarningText.font = NSFont.systemFont(ofSize: fontSize)
    }
    
    func setImage(imageURL: URL?) {
        guard let unwrappedImageURL = imageURL else {
            displayNoImage()
            return
        }
        
        guard let image = NSImage(contentsOf: unwrappedImageURL) else {
            displayNoImage()
            return
        }
        
        if let unwrappedWarningText = warningText {
            unwrappedWarningText.removeFromSuperview()
            warningText = nil
        }
        
        self.imageURL = unwrappedImageURL
        imageView.image = image
        
        resizeDocumentView(image: image)
    }
    
    func zoom(rate: CGFloat){
        if rate == 0 {
            return
        }
        
        let oldScrollPoint: NSPoint = NSPoint(x: self.scrollView.contentView.documentVisibleRect.origin.x,
                                              y: self.scrollView.contentView.documentVisibleRect.origin.y)
        
        let oldSize = scrollView.documentView!.frame
        
        let zoomW = scrollView.documentView!.frame.width + (10 * rate)
        let zoomH = scrollView.documentView!.frame.height + (10 * rate)
        
        if zoomW <= frame.width || zoomH <= frame.height {
            if let unwrappedImage = imageView.image {
                resizeDocumentView(image: unwrappedImage)
            }
            return
        }

        imageClipView.isZooming = true
        scrollView.documentView!.frame = CGRect(x: 0,
                                                y: 0,
                                                width: zoomW,
                                                height: zoomH)
        imageClipView.isZooming = false
        
        let zoomDiffSize = NSSize(width: scrollView.documentView!.frame.width - oldSize.width,
                              height: scrollView.documentView!.frame.height - oldSize.height)
        
        let point: NSPoint = NSPoint(x: oldScrollPoint.x + (zoomDiffSize.width / 2),
                                     y: oldScrollPoint.y + (zoomDiffSize.height / 2))

        scrollView.documentView?.scroll(point)
    }
    
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
    
    override func updateTrackingAreas() {
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow]
        addTrackingArea(NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil))
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
    
    //右クリック用。システムに任せる
    override func menu(for event: NSEvent) -> NSMenu? {
        return makeContextMenu()
    }
    
    //ctrl + 左クリック用。viewController側から呼ばれる
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
