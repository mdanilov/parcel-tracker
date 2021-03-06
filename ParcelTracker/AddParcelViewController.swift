//
//  AddParcelViewController.swift
//  ParcelTracker
//
//  Created by Максим Данилов on 23/11/2018.
//  Copyright © 2018 Maxim Danilov. All rights reserved.
//

import Cocoa
import CoreFoundation

class AddParcelViewController: NSViewController, NSTextFieldDelegate  {

    @IBOutlet weak var trackNumberTextField: NSTextField!
    @IBOutlet weak var carrierLabel: NSTextField!
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var carrierComboBox: NSComboBox!
    @IBOutlet weak var pinCodeBox: NSBox!
    @IBOutlet weak var pinCodeTextField: NSTextField!
    @IBOutlet weak var addingBox: NSBox!
    @IBOutlet weak var addingProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var addingTextField: NSTextField!
    
    let duplicateDetectedDialogMessage = NSLocalizedString("duplicateDetectedDialogMessage", comment: "Shown on alert when user tried to add already existing parcel")
    let addingProgressLocalStr = NSLocalizedString("addingProgress", comment: "Shown near the progress indicator in the adding mode")
    let changingProgressLocalStr = NSLocalizedString("changingProgress", comment: "Shown near the progress indicator in the changing mode")
    let addButtonLocalStr = NSLocalizedString("addButton", comment: "Add button text")
    let changeButtonLocalStr = NSLocalizedString("changeButton", comment: "Change button text")
    
    var query: MoyaposylkaService.Query?
    var carriers: [Carrier] = [] {
        didSet {
            if carriers.count > 1 {
                self.carrierLabel.isHidden = true
                self.carrierComboBox.isHidden = false
                self.selectedCarrier = carriers[0]
                self.carrierComboBox.reloadData()
                self.carrierComboBox.selectItem(at: 0)
            }
            else if carriers.count == 1 {
                self.selectedCarrier = carriers[0]
                self.carrierLabel.isHidden = false
                self.carrierLabel.stringValue = carriers[0].name
                self.carrierComboBox.isHidden = true
            }
            else {
                self.selectedCarrier = nil
                self.carrierLabel.stringValue = "--/--"
                self.carrierLabel.isHidden = false
                self.carrierComboBox.isHidden = true
            }
        }
    }
    var selectedCarrier: Carrier? {
        didSet {
            self.pinCodeBox.isHidden = true
            if let carrier = selectedCarrier {
                self.addButton.isEnabled = true
                if (carrier.code == "jde") {
                    self.pinCodeBox.isHidden = false
                }
            }
            else {
                self.addButton.isEnabled = false
            }
        }
    }
    
    enum WindowMode {
        case adding, changing
    }

    let vc = NSApplication.shared.mainWindow?.contentViewController as! ViewController
    var windowMode: WindowMode = .adding
    var index: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.trackNumberTextField.delegate = self as NSTextFieldDelegate
        self.carrierComboBox.dataSource = self as NSComboBoxDataSource
        
        self.addingTextField.stringValue = addingProgressLocalStr
        self.addButton.title = addButtonLocalStr
    }
    
    override func viewWillAppear() {
        self.pinCodeBox.isHidden = true
        self.addingBox.isHidden = true
        self.addButton.isEnabled = true
        self.addingProgressIndicator.stopAnimation(nil)
    }
    
    func initFromParcel(_ parcel: Parcel, index: Int) {
        self.nameTextField.stringValue = parcel.name
        self.trackNumberTextField.stringValue = parcel.barcode
        if let pinCode = parcel.pinCode {
            self.pinCodeTextField.stringValue = pinCode
        }
        sharedMoyaposylkaService.requestCarrier(parcel.barcode) { carriers in
            self.carriers = carriers
            if let carrier = carriers.enumerated().first(where: {$0.element.code == parcel.carrier.code}) {
                self.carrierComboBox.selectItem(at: carrier.offset)
                self.selectedCarrier = carrier.element
            }
        }
        
        self.addingTextField.stringValue = changingProgressLocalStr
        self.addButton.title = changeButtonLocalStr
        windowMode = .changing
        self.index = index
    }

    func controlTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else { return }
        print("Info: barcode value is changed \(textField.stringValue)")
        sharedMoyaposylkaService.requestCarrier(textField.stringValue) { carriers in
            self.carriers = carriers
        }
    }
    
    func dialogOK(message: String, info: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = info
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: self.view.window!)
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        if (self.query != nil) {
            self.query!.cancel()
            self.query = nil
        }
        self.addButton.isEnabled = true
        self.view.window!.close()
    }
    
    func isDuplicate(_ parcel: Parcel) -> Bool {
        if (windowMode == .adding) {
            return vc.parcels.contains(parcel)
        }
        else {
            return (vc.parcels[index!] != parcel) && vc.parcels.contains(parcel)
        }
    }
    
    @IBAction func addButtonClicked(_ sender: Any) {
        if (self.carriers.count > 1 && self.carrierComboBox.indexOfSelectedItem == -1) {
            self.carrierComboBox.selectItem(at: 0)
        }
        
        let carrier = selectedCarrier!
        
        let name: String
        if (self.nameTextField.stringValue.isEmpty) {
            let dateFormatter = DateFormatter()
            dateFormatter.setLocalizedDateFormatFromTemplate("MMMd")
            dateFormatter.locale = Locale.init(identifier: Locale.preferredLanguages[0])
            name = dateFormatter.string(from: Date()) + ", " + carrier.name
        } 
        else {
            name = self.nameTextField.stringValue
        }
        
        let parcelToAdd = Parcel(name: name, barcode: self.trackNumberTextField.stringValue, carrier: carrier)
        if (carrier.code == "jde") {
            parcelToAdd.pinCode = pinCodeTextField.stringValue
        }
        
        if (isDuplicate(parcelToAdd)) {
            let name = vc.parcels[vc.parcels.firstIndex(of: parcelToAdd)!].name
            dialogOK(message: duplicateDetectedDialogMessage, info: name)
        }
        else {
            self.addingBox.isHidden = false
            self.addButton.isEnabled = false
            self.addingProgressIndicator.startAnimation(nil)
            self.query = sharedMoyaposylkaService.requestParcelStatus(parcelToAdd.carrier.code, parcelToAdd.barcode, parcelToAdd.pinCode) { parcelStatus in
                DispatchQueue.main.async {
                    parcelToAdd.status = parcelStatus
                    if (self.windowMode == .changing) {
                        self.vc.parcels[self.index!] = parcelToAdd
                        self.vc.leftTableView.reloadData(forRowIndexes: [self.index!], columnIndexes: [0])
                        self.vc.statusTableView.reloadData()
                        
                        if (self.vc.leftTableView.selectedRow == self.index!) {
                            self.vc.selectedParcel = parcelToAdd
                        }
                    } else {
                        NotificationCenter.default.post(name: ViewController.newParcelAddedNotification, object: nil, userInfo: ["parcel": parcelToAdd])
                    }
                    
                    if let window = self.view.window {
                        window.close()
                    }
                }
            }
        }
    }
}

extension AddParcelViewController: NSComboBoxDelegate {
    func comboBoxSelectionDidChange(_ aNotification: Notification) {
        if (carrierComboBox.indexOfSelectedItem != -1) {
            selectedCarrier = carriers[carrierComboBox.indexOfSelectedItem]
        }
        else {
            selectedCarrier = nil
        }
    }
}

extension AddParcelViewController: NSComboBoxDataSource {
    func numberOfItems(in: NSComboBox) -> Int {
        return carriers.count
    }
    
    func comboBox(_ aComboBox: NSComboBox, objectValueForItemAt: Int) -> Any? {
        if (objectValueForItemAt > -1) {
            return self.carriers[objectValueForItemAt].name
        }
        else {
            return nil
        }
    }
}
