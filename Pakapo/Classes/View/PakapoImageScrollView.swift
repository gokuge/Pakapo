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
        switch event.modifierFlags.intersection(.deviceIndependentFlagsMask) {
        case [.control]:
            //次へ。ズームにする
            nextResponder?.scrollWheel(with: event)
            return
        default:
            break
        }
        //ウィンドウスクロール可能の場合はスクロール優先
        if canScrollClosure() {
            super.scrollWheel(with: event)
            return
        }
        
        //次へ。ページ送りにする
        nextResponder?.scrollWheel(with: event)
    }
}
