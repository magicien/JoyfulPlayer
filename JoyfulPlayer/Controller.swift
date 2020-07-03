//
//  Controller.swift
//  JoyfulPlayer
//
//  Created by magicien on 2020/06/21.
//  Copyright © 2020 DarkHorse. All rights reserved.
//

import JoyConSwift

class Controller: Identifiable, ObservableObject {
    let id: String
    let controller: JoyConSwift.Controller
    var hasLeft: Bool = false
    var hasRight: Bool = false
    @Published var leftHighTrack: Subtrack?
    @Published var leftLowTrack: Subtrack?
    @Published var rightHighTrack: Subtrack?
    @Published var rightLowTrack: Subtrack?
    var events: [RumbleEvent] = []
    
    init(controller: JoyConSwift.Controller) {
        self.id = controller.serialID
        self.controller = controller
        if controller is JoyConSwift.JoyConL {
            self.hasLeft = true
            self.hasRight = false
        } else if controller is JoyConSwift.JoyConR {
            self.hasLeft = false
            self.hasRight = true
        } else if controller is JoyConSwift.ProController {
            self.hasLeft = true
            self.hasRight = true
        }
    }
    
    func startLEDAnimation() {
        let cycleData = [
            HomeLEDPattern(intensity: 0x0F, fadeDuration: 1, duration: 4),
            HomeLEDPattern(intensity: 0x00, fadeDuration: 7, duration: 7)
        ]
        self.controller.setHomeLight(
            miniCycleDuration: 2,
            numCycles: 0,
            startIntensity: 0,
            cycleData: cycleData
        )
        self.controller.setPlayerLights(
            l1: .flash,
            l2: .flash,
            l3: .flash,
            l4: .flash
        )
    }
    
    func stopLEDAnimation() {
        self.controller.setHomeLight(
            miniCycleDuration: 0,
            numCycles: 0,
            startIntensity: 0,
            cycleData: []
        )
        self.controller.setPlayerLights(
            l1: .on,
            l2: .off,
            l3: .off,
            l4: .off
        )
    }
}
