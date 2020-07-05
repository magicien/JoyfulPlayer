//
//  AppDelegate.swift
//  JoyfulPlayer
//
//  Created by magicien on 2020/06/21.
//  Copyright © 2020 DarkHorse. All rights reserved.
//

import AppKit
import UserNotifications
import SwiftUI
import JoyConSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    
    let appEnv = AppEnv()
    
    // MARK: - App event handlers

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let playerView = PlayerView().environmentObject(self.appEnv)

        // Create the window and set the content view. 
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: playerView)
        window.makeKeyAndOrderFront(nil)
        
        // Set notification handlers
        NotificationCenter.default.addObserver(forName: .didStartPlaying, object: nil, queue: nil, using: self.didStartPlaying)
        NotificationCenter.default.addObserver(forName: .didStopPlaying, object: nil, queue: nil, using: self.didStopPlaying)

        // Set controller handlers
        self.appEnv.manager.connectHandler = { [weak self] controller in
            self?.connectController(controller)
        }
        self.appEnv.manager.disconnectHandler = { [weak self] controller in
            self?.disconnectController(controller)
        }
        _ = self.appEnv.manager.runAsync()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.appEnv.controllers.forEach { controller in
            controller.controller.setHCIState(state: .disconnect)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Controller handlers

    func connectController(_ controller: JoyConSwift.Controller) {
        let joycon = Controller(controller: controller)
        DispatchQueue.main.async {
            self.appEnv.controllers.append(joycon)
        }
        joycon.stopLEDAnimation()
    }

    func disconnectController(_ controller: JoyConSwift.Controller) {
        if let index = self.appEnv.controllers.firstIndex(where: {
            $0.controller.serialID == controller.serialID
        }) {
            DispatchQueue.main.async {
                self.appEnv.controllers.remove(at: index)
            }
        }
    }
    
    // MARK: - Custom Notifications
    
    var activity: NSObjectProtocol?
    
    func didStartPlaying(_ notification: Notification) {
        self.appEnv.controllers.forEach {
            $0.controller.enableVibration(enable: true)
            $0.startLEDAnimation()
        }
        self.appEnv.isPlaying = true
        self.activity = ProcessInfo.processInfo.beginActivity(options: .userInitiatedAllowingIdleSystemSleep, reason: "Keep firing timers even when the app is in the background")
    }
    
    func didStopPlaying(_ notification: Notification) {
        self.appEnv.controllers.forEach {
            $0.stopLEDAnimation()
            $0.controller.enableVibration(enable: false)
        }
        self.appEnv.isPlaying = false
        
        if let activity = self.activity {
            ProcessInfo.processInfo.endActivity(activity)
        }
        self.activity = nil
    }
}

