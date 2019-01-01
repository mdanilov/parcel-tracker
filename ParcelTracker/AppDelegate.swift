//
//  AppDelegate.swift
//  ParcelTracker
//
//  Created by Максим Данилов on 23/11/2018.
//  Copyright © 2018 Maxim Danilov. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var deleteParcelMenuItem: NSMenuItem!
    @IBOutlet weak var changeParcelMenuItem: NSMenuItem!
    
    func applicationWillFinishLaunching(_ aNotification: Notification) {
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }
    
    func applicationShouldHandleReopen(_ application: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            for window: AnyObject in application.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        let application = aNotification.object as! NSApplication
        guard let viewController = application.mainWindow!.contentViewController as? ViewController else {
            return
        }
        viewController.saveParcels()
    }
    
    @IBOutlet weak var addParcelMenuItem: NSMenuItem!
    
}

