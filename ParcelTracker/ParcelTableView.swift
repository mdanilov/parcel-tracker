//
//  ParcelTableView.swift
//  ParcelTracker
//
//  Created by Максим Данилов on 03/01/2019.
//  Copyright © 2019 Maxim Danilov. All rights reserved.
//

import Cocoa

class ParcelTableView: NSTableView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    var clickedItem: Int = -1
    
    override func menu(for event: NSEvent) -> NSMenu? {
        clickedItem = self.row(at: self.convert(event.locationInWindow, from: nil))
        
        // If the click occurred outside of any of the playlist rows (i.e. empty space), don't show the menu
        if (clickedItem == -1) {
            return nil
        }
        
        return self.menu
    }
    
}
