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
    
    // MARK: - init
    override func viewWillAppear() {
        super.viewWillAppear()
        willMakeView()
    }
    
    func willMakeView() {
        setPageFeed(pageFeedRight: UserDefaults.standard.bool(forKey: AppDelegate.PAGE_FEED_RIGHT))
        setSearchChildEnable(enable: UserDefaults.standard.bool(forKey: AppDelegate.SEARCH_CHILD_ENABLE))
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
}
