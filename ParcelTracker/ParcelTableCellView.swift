//
//  ParcelTableCellView.swift
//  ParcelTracker
//
//  Created by Максим Данилов on 25/11/2018.
//  Copyright © 2018 Maxim Danilov. All rights reserved.
//

import Cocoa

class ParcelTableCellView: NSTableCellView {
    
    // MARK: Properties
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var statusImage: NSImageView!
    @IBOutlet weak var lastStatusTextField: NSTextField!
    @IBOutlet weak var deliveringTimeTextField: NSTextField!
    
    let noDataLocalStr = NSLocalizedString("noData", comment: "No information is available for the parcel tracking status")
    
    override var objectValue: Any? {
        didSet {
            guard let parcel = objectValue as? Parcel else {
                nameTextField.stringValue = ""
                statusImage.isHidden = true
                deliveringTimeTextField.isHidden = true
                return
            }
            
            nameTextField.stringValue = parcel.name
            statusImage.isHidden = false
            deliveringTimeTextField.isHidden = true
            
            var templateImage: NSImage?
            if let status = parcel.status, status.events.count > 0  {
                if (status.delivered != nil && status.delivered!) {
                    templateImage = NSImage(named: "OkImage")
                }
                else if let deliveringTime = status.deliveringTime {
                    deliveringTimeTextField.stringValue = String(deliveringTime)
                    deliveringTimeTextField.isHidden = false
                    statusImage.isHidden = true
                }
                else {
                    templateImage = NSImage(named: "TruckImage")
                }
            }
            else {
                templateImage = NSImage(named: "QuestionMarkImage")
            }
            
            if (templateImage != nil) {
                statusImage.image = templateImage!
                statusImage.contentTintColor = NSColor(named: "StatusImageColor") ?? NSColor.clear
            }
            
            lastStatusTextField.stringValue = parcel.status?.events.first?.operation ?? noDataLocalStr
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
}
