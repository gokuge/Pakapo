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
        
        //特定の表示形式ではウィンドウのスクロールを優先する
        if canScrollClosure() {
            super.scrollWheel(with: event)
            return
        }
        
        //スクロールでの動作はページ送りにする
        nextResponder?.scrollWheel(with: event)
    }
}
