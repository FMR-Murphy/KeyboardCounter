//
//  AppDelegate.swift
//  KeyboardCounter
//
//  Created by Fang on 2020/8/13.
//

import Cocoa
import SwiftUI

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let launcherAppIdentifier = "com.murphy.KeyboardCounter.helper"
        
        var startedAtLogin = false
        for app in NSWorkspace.shared.runningApplications {
            if app.bundleIdentifier == launcherAppIdentifier {
                startedAtLogin = true
                break
            }
        }
        
        if startedAtLogin {
            DistributedNotificationCenter.default().postNotificationName(NSNotification.Name(rawValue: "killHelper"), object: Bundle.main.bundleIdentifier!, userInfo: nil, options: .deliverImmediately)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        print("\(aNotification)")
    }


}

