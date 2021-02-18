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
        
        // Create the window and set the content view.
//        window = NSWindow(
//            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
//            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
//            backing: .buffered, defer: false)
//        window.isReleasedWhenClosed = false
//        window.center()
//        window.setFrameAutosaveName("Main Window")
//        window.contentView = NSHostingView(rootView: contentView)
//        window.makeKeyAndOrderFront(nil)

        var components = (Bundle.main.bundlePath as NSString).pathComponents as NSArray
        components = components.subarray(with: NSMakeRange(0, components.count - 4)) as NSArray
        
        let path = NSString.path(withComponents: components as! [String])
        NSWorkspace.shared.launchApplication(path)
        NSApp.terminate(nil)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        print("\(aNotification)")
    }


}

