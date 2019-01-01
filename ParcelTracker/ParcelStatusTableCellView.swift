//
//  ParcelStatusTableCellView.swift
//  ParcelTracker
//
//  Created by Максим Данилов on 01/12/2018.
//  Copyright © 2018 Maxim Danilov. All rights reserved.
//

import Cocoa

class ParcelStatusTableCellView: NSTableCellView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    @IBOutlet weak var descriptionTextField: NSTextField!
    @IBOutlet weak var locationTextField: NSTextField!
    @IBOutlet weak var dateTextField: NSTextField!
}
