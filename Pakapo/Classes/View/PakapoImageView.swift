//
//  PakapoImageView.swift
//  Pakapo
//
//  Created by gokuge on 2019/12/06.
//  Copyright © 2019 gokuge. All rights reserved.
//

import Cocoa

class PakapoImageView: NSView {
    
    var getFileURLClosure:(() -> URL?)!
    var getDirURLClosure:(() -> URL?)!

    let imageView: NSImageView = NSImageView()
    var warningText: NSTextField?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        print("dragging entered")
        
        return NSDragOperation.copy
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return NSDragOperation.copy
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let draggedFilePath = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil)
        
        guard let unwrappedDraggedFilePath = draggedFilePath else {
            return false
        }
        
        if unwrappedDraggedFilePath.count != 1 {
            return false
        }
        
        return true
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        //https://stackoverflow.com/questions/44537356/swift-4-nsfilenamespboardtype-not-available-what-to-use-instead-for-registerfo
        let draggedFilePath = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil)
        
        guard let unwrappedDraggedFilePath = draggedFilePath else {
            return
        }
        
        if unwrappedDraggedFilePath.count != 1 {
            return
        }
        
        guard let unwrappedFileURL = unwrappedDraggedFilePath[0] as? URL else {
            return
        }
        
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: unwrappedFileURL.path, isDirectory: &isDir) {
            return
        }
        
        if isDir.boolValue {
            //directory
            
            return
        }
        
        guard NSImage(contentsOf: unwrappedFileURL) != nil else {
            return
        }

        //表示可能なファイル
        
        print("dragging entered2")
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        imageView.frame = frameRect
        imageView.wantsLayer = true
        imageView.layer?.backgroundColor = NSColor.black.cgColor
        imageView.imageScaling = NSImageScaling.scaleProportionallyUpOrDown
        
        registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        
//        addSubview(imageView)
    }
    
    func resizeFrame(frame: CGRect) {
        self.frame = frame
        imageView.frame = frame
        
        resizeWarningTextView()
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
            return
        }
        
        addSubview(unwrappedWarningText)
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
