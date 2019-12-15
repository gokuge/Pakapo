//
//  PakapoImageScrollView.swift
//  Pakapo
//
//  Created by gokuge on 2019/12/15.
//  Copyright © 2019 gokuge. All rights reserved.
//

import Cocoa

class PakapoImageScrollView: NSScrollView {
    
    var canScrollClosure:(() -> Bool)!
    
    override func scrollWheel(with event: NSEvent) {
        
        if canScrollClosure() {
            super.scrollWheel(with: event)
            return
        }
        
        nextResponder?.scrollWheel(with: event)
    }
}
