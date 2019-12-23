//
//  PakapoTabViewController.swift
//  Pakapo
//
//  Created by gokuge on 2019/12/23.
//  Copyright © 2019 gokuge. All rights reserved.
//

import Cocoa

class PakapoTabViewController: NSTabViewController {
    
    static let GENERAL_VIEW_HEIGHT: CGFloat = 200
    static let DETAIL_VIEW_HEIGHT: CGFloat = 200
    
    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, willSelect: tabViewItem)
        
        guard let window = view.window else {
            return
        }
        
        guard let label = tabViewItem?.label else {
            return
        }
        var height: CGFloat = 0
        
        switch label {
        case "一般":
            height = PakapoTabViewController.GENERAL_VIEW_HEIGHT
        case "詳細":
            height = PakapoTabViewController.DETAIL_VIEW_HEIGHT
        default:
            break
        }
        
        let y = window.frame.origin.y + (window.frame.size.height - height)

        window.setFrame(CGRect(x: window.frame.origin.x,
                               y: y,
                               width: window.frame.size.width,
                               height: height),
                        display: false,
                        animate: true
        )
    }
}
