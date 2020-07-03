//
//  TrackCellView.swift
//  JoyfulPlayer
//
//  Created by magicien on 2020/07/01.
//  Copyright © 2020 DarkHorse. All rights reserved.
//

import SwiftUI
import JoyConSwift

struct TrackCellView: View, Identifiable {
    @EnvironmentObject var env: AppEnv
    
    let id = UUID()
    @ObservedObject var controller: Controller
    let left: Bool
    let high: Bool
    
    var controllerName: String {
        if self.controller.controller is ProController {
            return "ProCon"
        } else if self.controller.controller is JoyConL {
            return "JoyCon"
        } else if self.controller.controller is JoyConR {
            return "JoyCon"
        }
        
        return "Unknown"
    }
    
    var track: Subtrack? {
        get {
            if self.left {
                if self.high {
                    return self.controller.leftHighTrack
                } else {
                    return self.controller.leftLowTrack
                }
            } else {
                if self.high {
                    return self.controller.rightHighTrack
                } else {
                    return self.controller.rightLowTrack
                }
            }
        }
        set {
            if self.left {
                if self.high {
                    self.controller.leftHighTrack = newValue
                } else {
                    self.controller.leftLowTrack = newValue
                }
            } else {
                if self.high {
                    self.controller.rightHighTrack = newValue
                } else {
                    self.controller.rightLowTrack = newValue
                }
            }
        }
    }
    
    var trackName: String? {
        return self.track?.name
    }
    
    var body: some View {
        return HStack {
            Text("\(self.controllerName) \(self.left ? "L" : "R") \(self.high ? "high" : "low")")
                .frame(width: 100, alignment: .leading)

            Text(self.track?.name ?? "Not assigned")
        }
    }
}
