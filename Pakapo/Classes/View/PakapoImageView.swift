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
    let scrollView: PakapoImageScrollView = PakapoImageScrollView()
    var draggingView: DraggingView!
    var warningText: NSTextField?
    
    var pinchIn: Bool = false
    var mouseMovedEndWorkItem: DispatchWorkItem?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        imageView.frame = frameRect
        imageView.wantsLayer = true
        imageView.imageScaling = NSImageScaling.scaleProportionallyUpOrDown
        
        if viewStyle.rawValue == ViewStyle.originalSizeView.rawValue {
            imageView.imageScaling = NSImageScaling.scaleNone
        }

        draggingView = DraggingView(frame: frameRect)
        draggingView.dropClosure = { (url: URL) in
            self.dropClosure(url)
        }
        
        scrollView.frame = frameRect
        scrollView.backgroundColor = NSColor.black
        scrollView.documentView = imageView
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true

        scrollView.canScrollClosure = {
            
            if self.viewStyle.rawValue == ViewStyle.defaultView.rawValue {
                return false
            }
            
            return true
        }
        addSubview(scrollView)
        addSubview(draggingView)
    }
    
    func resizeFrame(frame: CGRect) {
        let point: NSPoint = NSPoint(x: scrollView.contentView.documentVisibleRect.origin.x,
                                     y: scrollView.contentView.documentVisibleRect.origin.y)

        self.frame = frame
        draggingView.frame = frame
        imageView.frame = frame
        scrollView.frame = frame
        
        if let unwrappedImage = imageView.image {
            resizeDocumentView(image: unwrappedImage)
            scrollView.contentView.scroll(point)
        }
        
        resizeWarningTextView()
    }
    
    func resizeDocumentView(image: NSImage) {
        
        if viewStyle.rawValue == ViewStyle.defaultView.rawValue {
            return
        }
        
        let imageRep: NSBitmapImageRep  = NSBitmapImageRep(data: image.tiffRepresentation!)!
        let pixelW: CGFloat = CGFloat(imageRep.pixelsWide)
        let pixelH: CGFloat = CGFloat(imageRep.pixelsHigh)
        let ratio: CGFloat = frame.width / pixelW
        
        switch viewStyle.rawValue {
        case ViewStyle.widthFitView.rawValue:
            scrollView.documentView?.frame = CGRect(x: 0.0,
                                                    y: 0.0,
                                                    width: pixelW * ratio,
                                                    height: pixelH * ratio
            )
        case ViewStyle.spreadView.rawValue:
            //初期値は横フィット
            var spreadW: CGFloat = pixelW * ratio
            var spreadH: CGFloat = pixelH * ratio
            
            if (pixelW > SPREAD_WIDTH){
                //既定値より大きい場合にのみ見開き設定(横2倍フィット)
                spreadW *= 2
                spreadH *= 2
            }
            
            scrollView.documentView?.frame = CGRect(x: 0.0,
                                                    y: 0.0,
                                                    width: spreadW,
                                                    height: spreadH
            )
        case ViewStyle.originalSizeView.rawValue:
            //どちらかViewのsizeより小さかった場合はdefaultViewと同じ表示状態にする
            if (pixelW <= frame.width || pixelH <= frame.height){
                return
            }
            
            scrollView.documentView?.frame = CGRect(x: 0,
                                                    y: 0,
                                                    width: pixelW,
                                                    height: pixelH)
            
        default:
            break
        }
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
        if event.deltaY > 0 {
            leftClickClosure()
        } else if event.deltaY < 0 {
            rightClickClosure()
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
        var tmpStyle: Int = viewStyle.rawValue
        if pinchIn {
            if viewStyle.rawValue == ViewStyle.defaultView.rawValue {
                return
            }
            tmpStyle -= 1
        } else {
            if viewStyle.rawValue == ViewStyle.originalSizeView.rawValue {
                return
            }
            tmpStyle += 1
        }
        
        changeViewStyleClosure(tmpStyle)
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
