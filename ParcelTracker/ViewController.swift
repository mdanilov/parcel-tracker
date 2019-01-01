//
//  ViewController.swift
//  ParcelTracker
//
//  Created by Максим Данилов on 23/11/2018.
//  Copyright © 2018 Maxim Danilov. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var leftTableView: NSTableView!
    @IBOutlet weak var statusTableView: NSTableView!
    @IBOutlet weak var leftHeaderView: NSView!
    @IBOutlet weak var leftScrollView: NSScrollView!
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("parcels.json")
    
    static let newParcelAddedNotification = Notification.Name("newParcelAdded")
    
    let weightLocalStr = NSLocalizedString("weight", comment: "Parcel weight")
    let datePlaceholderForUnknownStatus = NSLocalizedString("datePlaceholderForUnknownStatus", comment: "Date placeholder for unknown parcel status")
    let yesLocalStr = NSLocalizedString("yes", comment: "yes")
    let cancelLocalStr = NSLocalizedString("cancel", comment: "cancel")
    let deleteAlertQuestionLocalStr = NSLocalizedString("deleteAlertQuestion", comment: "Question in alert window when user tries to delete the selected parcel")
    let descriptionPlaceholderForUnknownStatus = NSLocalizedString("descriptionPlaceholderForUnknownStatus", comment: "Description placeholder for unknown parcel status")
    
    let activity = NSBackgroundActivityScheduler(identifier: "com.example.ParcelTracker.updateparcelstatus")
    
    var parcels: [Parcel] = []
    var selectedParcel: Parcel? {
        didSet {
            if let parcel = selectedParcel {
                self.headerTrackNamburTextField.stringValue = parcel.barcode
                self.headerCarrierTextField.stringValue = parcel.carrier.name
                self.headerNameTextField.stringValue = parcel.name
                self.statusTableView.reloadData()
                self.leftHeaderView.isHidden = false
                self.leftScrollView.isHidden = false
                
                self.app.changeParcelMenuItem.isEnabled = true
                self.app.deleteParcelMenuItem.isEnabled = true
                
                if let wc = self.view.window?.windowController as? WindowController {
                    wc.deleteButton.isEnabled = true
                }
            }
            else {
                self.leftHeaderView.isHidden = true
                self.leftScrollView.isHidden = true
                
                self.app.changeParcelMenuItem.isEnabled = false
                self.app.deleteParcelMenuItem.isEnabled = false
                
                if let wc = self.view.window?.windowController as? WindowController {
                    wc.deleteButton.isEnabled = false
                }
            }
        }
    }
    
    let app = NSApplication.shared.delegate as! AppDelegate
    var lastSelectedRow: Int = -1
    
    func deleteSelectedParcelWithUserQuestion() {
        func dialogOKCancel(question: String, _ text: String? = "") -> Bool {
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = text ?? ""
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: yesLocalStr)
            alert.addButton(withTitle: cancelLocalStr)
            return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
        }
        
        let answer = dialogOKCancel(question: deleteAlertQuestionLocalStr)
        
        if (answer) {
            deleteSelectedParcel()
        }
    }
    
    func deleteSelectedParcel() {
        if (leftTableView.selectedRow != -1) {
            var selectedRow = self.leftTableView.selectedRow
            self.parcels.remove(at: selectedRow)
            self.leftTableView.reloadData()
            
            if (selectedRow >= self.parcels.count) {
                selectedRow = self.parcels.count - 1
            }
            
            if (selectedRow > -1) {
                self.leftTableView.deselectAll(nil)
                self.leftTableView.selectRowIndexes([selectedRow], byExtendingSelection: false)
                self.selectedParcel = parcels[selectedRow]
            }
            else {
                self.selectedParcel = nil
            }
        }
    }
    
    func loadParcels() -> [Parcel]? {
        guard let data = FileManager.default.contents(atPath: ViewController.ArchiveURL.path) else {
            print("Error: Couldn't load data from file: can't open file")
            return nil
        }
        
        let decoder = JSONDecoder()
        guard let result = try? decoder.decode([Parcel].self, from: data) else {
            print("Error: Couldn't load data from file: can't decode data")
            return nil
        }
        
        return result
    }
    
    func saveParcels() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(parcels) {
            try? data.write(to: ViewController.ArchiveURL)
        }
    }
    
    var updateInProgress: Bool = false
    
    func updateAllStatus(invokedByUser: Bool) {
        var updateProgressIndicator: NSProgressIndicator?
        
        if (invokedByUser) {
            if (self.updateInProgress) {
                return
            }
            else {
                self.updateInProgress = true
            }
            
            if let windowController = self.view.window?.windowController as? WindowController {
                updateProgressIndicator = windowController.updateProgressIndicator
            }
            
            if (updateProgressIndicator != nil) {
                updateProgressIndicator!.isHidden = false
                updateProgressIndicator!.startAnimation(nil)
            }
        }
        
        var numberOfRequests = parcels.count
        for parcel in parcels {
            let curParcel = parcel
            sharedMoyaposylkaService.requestParcelStatus(parcel.carrier.code, parcel.barcode, parcel.pinCode) { parcelStatus in
                DispatchQueue.main.async {
                    numberOfRequests -= 1
                    if (numberOfRequests <= 0) {
                        if (invokedByUser) {
                            self.updateInProgress = false
                            if (updateProgressIndicator != nil) {
                                updateProgressIndicator!.stopAnimation(nil)
                                updateProgressIndicator!.isHidden = true
                            }
                        }
                    }
                    
                    let status = parcelStatus ?? ParcelStatus()
                    curParcel.status = status
                    if (curParcel === self.selectedParcel) {
                        self.statusTableView.reloadData()
                    }
                    
                    if let rowIndex = self.parcels.firstIndex(of: curParcel) {
                        self.leftTableView.reloadData(forRowIndexes: [rowIndex], columnIndexes: [0])
                    }

                    self.saveParcels()
                }
            }
        }
    }
    
    @IBAction func updateButtonClicked(_ sender: Any) {
        updateAllStatus(invokedByUser: true)
    }
    
    @IBOutlet weak var headerNameTextField: NSTextField!
    @IBOutlet weak var headerTrackNamburTextField: NSTextField!
    @IBOutlet weak var headerCarrierTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !FileManager.default.fileExists(atPath: ViewController.ArchiveURL.path) {
            FileManager.default.createFile(atPath: ViewController.ArchiveURL.path, contents: nil)
        }
        
        self.lastSelectedRow = leftTableView.selectedRow
        self.parcels = loadParcels() ?? []

        leftTableView.delegate = self
        leftTableView.dataSource = self
        leftTableView.selectionHighlightStyle = NSTableView.SelectionHighlightStyle.none
        
        statusTableView.delegate = self
        statusTableView.dataSource = self
        
        leftHeaderView.isHidden = true
        leftScrollView.isHidden = true
        
        activity.repeats = true
        activity.interval = 30 * 60
        activity.qualityOfService = QualityOfService.background
        activity.tolerance = 15 * 60
        activity.schedule() { (completion: NSBackgroundActivityScheduler.CompletionHandler) in
            self.updateAllStatus(invokedByUser: false)
            completion(NSBackgroundActivityScheduler.Result.finished)
        }
        
        if (!self.parcels.isEmpty) {
            self.selectedParcel = parcels[0]
            self.leftTableView.selectRowIndexes([0], byExtendingSelection: false)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(onNotification(notification:)), name: ViewController.newParcelAddedNotification, object: nil)
    }
    
    @objc func onNotification(notification: Notification) {
        if let parcel = notification.userInfo?["parcel"] as? ParcelTracker.Parcel {
            parcels.insert(parcel, at: 0)
            self.saveParcels()
            self.statusTableView.reloadData()
            self.leftTableView.reloadData()
        }
    }
    
    @IBAction func deleteButtonClicked(_ sender: Any) {
        deleteSelectedParcelWithUserQuestion()
    }
    
    @IBAction func changeButtonClicked(_ sender: Any) {
        return
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        if let wc = storyboard.instantiateController(withIdentifier: "AddParcelWindowID") as? NSWindowController, let vc = wc.contentViewController as? AddParcelViewController {
            vc.parcel = selectedParcel
            wc.showWindow(nil)
        }
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == leftTableView {
            return self.parcels.count
        }
        else {
            if let available = self.selectedParcel?.statusAvailable(), available {
                return self.selectedParcel!.status!.events.count
            }
            else {
                return 1
            }
        }
    }
}

extension ViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == leftTableView {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ParcelTableCellID"), owner: nil) as? ParcelTableCellView {
                cell.objectValue = parcels[row]
                return cell
            }
            return nil
        }
        else {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "StatusTableCellID"), owner: nil) as? ParcelStatusTableCellView {
                if let available = self.selectedParcel?.statusAvailable(), available, let element = selectedParcel?.status?.events[row] {
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    dateFormatter.locale = Locale.init(identifier: "en_GB")
                    
                    cell.dateTextField.stringValue = dateFormatter.string(from: element.date)
                    cell.descriptionTextField.stringValue = element.operation
                    
                    if (row == 0) {
                        var weightStr: String = ""
                        let massFormatter = MassFormatter()
                        if let weight = selectedParcel!.status!.weight {
                            weightStr = String(", ") + weightLocalStr + String(" - ") + massFormatter.string(fromKilograms: Double(weight))
                        }
                        cell.descriptionTextField.stringValue += weightStr
                    }
                    
                    if let location = element.location {
                        cell.locationTextField.isHidden = false
                        cell.locationTextField.stringValue = location
                    }
                    else {
                        cell.locationTextField.isHidden = true
                    }
                    return cell
                }
                else {
                    cell.dateTextField.stringValue = datePlaceholderForUnknownStatus
                    cell.descriptionTextField.stringValue = descriptionPlaceholderForUnknownStatus
                    cell.locationTextField.isHidden = true
                    return cell
                }
            }
            return nil
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let table = notification.object as? NSTableView, table == leftTableView {
            let selectedRow = self.leftTableView.selectedRow
            if (selectedRow != -1) {
                selectedParcel = parcels[selectedRow]
                if let row = table.rowView(atRow: selectedRow, makeIfNecessary: true) {
                    row.backgroundColor = NSColor(named: "TableSelectionColor") ?? NSColor.clear
                }
            }
            else {
                selectedParcel = nil
            }
            
            if self.lastSelectedRow > -1, self.lastSelectedRow < self.leftTableView.numberOfRows, self.lastSelectedRow != selectedRow, let row = table.rowView(atRow: self.lastSelectedRow, makeIfNecessary: false) {
                row.backgroundColor = NSColor.clear
            }
            
            self.lastSelectedRow = leftTableView.selectedRow
        }
    }
}
