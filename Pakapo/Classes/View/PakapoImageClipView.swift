//
//  PakapoImageClipView.swift
//  Pakapo
//
//  Created by gokuge on 2019/12/17.
//  Copyright © 2019 gokuge. All rights reserved.
//

import Cocoa

class PakapoImageClipView: NSClipView {
    
    var isZooming = false
    
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        
        if !isZooming {
            return rect
        }
        
        if let containerView = documentView {
            //中心
            rect.origin.x = (containerView.frame.width - rect.width ) / 2
            rect.origin.y = (containerView.frame.height - rect.height ) / 2
        }

        return rect
    }
}
