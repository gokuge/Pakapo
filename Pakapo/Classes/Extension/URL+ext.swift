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
        //使い方的にdirectoryのURLは来ない様にしたいが、念の為
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            return false
        }
        
        if isDir.boolValue {
            return false
        }

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
}
