//
//  WindowController.swift
//  ParcelTracker
//
//  Created by Максим Данилов on 16/12/2018.
//  Copyright © 2018 Maxim Danilov. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    @IBOutlet weak var updateProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var deleteButton: NSButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

}
