//
//  PreferenceGeneralViewController.swift
//  Pakapo
//
//  Created by gokuge on 2019/12/23.
//  Copyright © 2019 gokuge. All rights reserved.
//

import Cocoa

class PreferenceGeneralViewController: NSViewController {
    
    @IBOutlet weak var pageFeedPopUpButton: NSPopUpButton!
    @IBOutlet weak var searchChildEnableCheckBox: NSButton!
    @IBOutlet weak var specifiedDirPathLabel: NSTextField!
    
    // MARK: - init
    override func viewWillAppear() {
        super.viewWillAppear()
        willMakeView()
    }
    
    func willMakeView() {
        setPageFeed(pageFeedRight: UserDefaults.standard.bool(forKey: AppDelegate.PAGE_FEED_RIGHT))
        setSearchChildEnable(enable: UserDefaults.standard.bool(forKey: AppDelegate.SEARCH_CHILD_ENABLE))
        setSpecifiedDir()
    }
    
    @IBAction func pageFeedChange(_ sender: Any) {
        let pageFeedPopUpButton = sender as! NSPopUpButton
        setPageFeed(pageFeedRight: !NSNumber(value: pageFeedPopUpButton.selectedItem!.tag).boolValue)
    }
    
    func setPageFeed(pageFeedRight: Bool) {
        if pageFeedRight {
            pageFeedPopUpButton.itemArray[0].state = NSControl.StateValue.on
            pageFeedPopUpButton.itemArray[1].state = NSControl.StateValue.off
            pageFeedPopUpButton.selectItem(withTag: 0)
            UserDefaults.standard.set(true, forKey: AppDelegate.PAGE_FEED_RIGHT)
        } else {
            pageFeedPopUpButton.itemArray[0].state = NSControl.StateValue.off
            pageFeedPopUpButton.itemArray[1].state = NSControl.StateValue.on
            pageFeedPopUpButton.selectItem(withTag: 1)
            UserDefaults.standard.set(false, forKey: AppDelegate.PAGE_FEED_RIGHT)
        }
    }
    
    @IBAction func searchChildEnableChange(_ sender: Any) {
        let searchChildEnableCheckBoxButton = sender as! NSButton
        setSearchChildEnable(enable: NSNumber(value: searchChildEnableCheckBoxButton.state.rawValue).boolValue)
    }
    
    func setSearchChildEnable(enable: Bool) {
        if enable {
            searchChildEnableCheckBox.state = NSControl.StateValue.on
            UserDefaults.standard.set(true, forKey: AppDelegate.SEARCH_CHILD_ENABLE)
        } else {
            searchChildEnableCheckBox.state = NSControl.StateValue.off
            UserDefaults.standard.set(false, forKey: AppDelegate.SEARCH_CHILD_ENABLE)
        }
    }
    
    @IBAction func openSpecifiedDir(_ sender: Any) {
        openPanel()
    }
    
    func openPanel() {
        guard let window = self.view.window else {
            return
        }

        let openImagePanel: NSOpenPanel = NSOpenPanel()

        openImagePanel.allowsMultipleSelection = false
        openImagePanel.canCreateDirectories    = false
        openImagePanel.canChooseDirectories    = true
        openImagePanel.canChooseFiles          = false

        //読み込み可能なファイルのみ対象とする(画像 + zip)
        openImagePanel.allowedFileTypes        = NSImage.imageTypes + ["zip"]
        
        openImagePanel.beginSheetModal(for: window, completionHandler: { (response) in

            if response != NSApplication.ModalResponse.OK {
                return
            }
            
            guard let unwrappedURL = openImagePanel.url else {
                return
            }
            UserDefaults.standard.set(unwrappedURL, forKey: AppDelegate.SPECIFIED_DIR)
            self.specifiedDirPathLabel.stringValue = unwrappedURL.path
        })
    }
    
    func setSpecifiedDir() {
        guard let saved = UserDefaults.standard.url(forKey: AppDelegate.SPECIFIED_DIR) else {
            return
        }
                
        specifiedDirPathLabel.stringValue = saved.path
    }
}
