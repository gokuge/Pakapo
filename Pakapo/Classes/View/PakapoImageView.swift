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
        case originalSizeView
        case spreadView
    }
    
    var getFileURLClosure:(() -> URL?)!
    var getDirURLClosure:(() -> URL?)!
    var dropClosure:((URL) -> Void)!

    let imageView: NSImageView = NSImageView()
    let scrollView: PakapoImageScrollView = PakapoImageScrollView()
    var draggingView: DraggingView!
    var warningText: NSTextField?
    
    var viewStyle: ViewStyle = ViewStyle.defaultView
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        imageView.frame = frameRect
        imageView.wantsLayer = true
        imageView.imageScaling = NSImageScaling.scaleProportionallyUpOrDown

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
        
        resizeDocumentView(image: unwrappedImage)
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
    
    // MARK: - click event
    override func menu(for event: NSEvent) -> NSMenu? {
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
