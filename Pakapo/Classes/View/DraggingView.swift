//
//  DraggingView.swift
//  Pakapo
//
//  Created by gokuge on 2019/12/13.
//  Copyright © 2019 gokuge. All rights reserved.
//

import Cocoa

class DraggingView: NSView {
    
    var dropClosure:((URL) -> Void)!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return NSDragOperation.copy
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return NSDragOperation.copy
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if canDropFileURL(sender: sender) != nil {
            return true
        }
        
        return false
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        
        //ドロップ位置がviewの範囲外だった場合は何もしない
        if !frame.contains(sender.draggingLocation) {
            return
        }
        
        if let dropURL = canDropFileURL(sender: sender) {
            dropClosure(dropURL)
        }
    }
    
    func canDropFileURL(sender: NSDraggingInfo) -> URL? {
        //https://stackoverflow.com/questions/44537356/swift-4-nsfilenamespboardtype-not-available-what-to-use-instead-for-registerfo
        let draggedFilePath = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil)
        
        guard let unwrappedDraggedFilePath = draggedFilePath else {
            return nil
        }
        
        if unwrappedDraggedFilePath.count != 1 {
            return nil
        }
        
        guard let unwrappedURL = unwrappedDraggedFilePath[0] as? URL else {
            return nil
        }
        
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: unwrappedURL.path, isDirectory: &isDir) {
            return nil
        }
        
        if isDir.boolValue {
            return unwrappedURL
        }
        
        if unwrappedURL.lastPathComponent.hasSuffix(".zip") {
            return unwrappedURL
        }
        
        if !unwrappedURL.isImageTypeURL() {
            return nil
        }
        
        guard NSImage(contentsOf: unwrappedURL) != nil else {
            return nil
        }
        
        return unwrappedURL
    }
}
