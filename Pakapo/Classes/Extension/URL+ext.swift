//
//  URL+ext.swift
//  Pakapo
//
//  Created by gokuge on 2019/12/13.
//  Copyright © 2019 gokuge. All rights reserved.
//

import Cocoa

extension URL {
    func isImageTypeURL() -> Bool{
        guard let lastPath = lastPathComponent.components(separatedBy: ".").last else {
            return false
        }
        
        let customTypes = ["jpg","pct"]
        let types = NSImage.imageTypes + customTypes
        
        for type in types {
            let typeComponents = type.components(separatedBy: ".")

            if lastPath.contains(typeComponents.last!) {
                return true
            }
        }
        
        return false
    }
    
    func lastPathComponent() -> String {
        let nsstringPath = path as NSString
        return nsstringPath.lastPathComponent
    }
    
    func isEqual(url: URL) -> Bool {
        
        //現状Pakapoで使っているのはaddingPercentEncoding(withAllowedCharacters: .urlPathAllowed)のみなので、単純に比較する
        guard let strA: String = self.absoluteString.removingPercentEncoding,
              let strB: String = url.absoluteString.removingPercentEncoding else {
                return false
        }
        
        if strA != strB {
            return false
        }
        
        return true
    }
}
