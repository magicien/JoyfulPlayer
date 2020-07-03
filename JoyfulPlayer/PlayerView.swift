//
//  PlayerView.swift
//  JoyfulPlayer
//
//  Created by magicien on 2020/06/21.
//  Copyright © 2020 DarkHorse. All rights reserved.
//

import SwiftUI
import JoyConSwift

struct PlayerView: View {
    @EnvironmentObject var env: AppEnv
    
    @State var fileName: String = ""
    @State var duration: Double = 0
    @State var isReady: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            self.openButton
            self.fileInfoText
            self.assignButton
            self.controllerTable
            self.convertButton
            if self.env.isPlaying {
                self.pauseButton
            } else {
                self.playButton
            }
        }.padding(10)
    }
    
    var openButton: some View {
        Button(action: {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.allowedFileTypes = ["mid"]
            panel.begin { (result) -> Void in
                if result == .OK {
                    guard let url = panel.url else { return }
                    do {
                        try self.env.player.load(url: url)
                        
                        self.fileName = url.lastPathComponent
                        self.duration = self.env.player.duration
                        self.isReady = false
                        self.env.controllers.forEach {
                            $0.leftHighTrack = nil
                            $0.leftLowTrack = nil
                            $0.rightHighTrack = nil
                            $0.rightLowTrack = nil
                        }
                    } catch {
                        let alert = NSAlert()
                        alert.messageText = "Failed to open the file"
                        alert.runModal()
                    }
                }
            }
        }) {
            if self.fileName == "" {
                Text("1. Open MIDI File")
            } else {
                Text("1. Change MIDI File")
            }
        }
    }
    
    var fileInfoText: some View {
        let minutes: Int = Int(floor(self.duration / 60))
        let seconds: Int = Int(self.duration.truncatingRemainder(dividingBy: 60))
        
        return VStack(alignment: .leading, spacing: 3) {
            if self.fileName != "" {
                Text("File name: \(self.fileName)")
                Text("Duration: \(minutes):\(seconds)")
                Text("Num tracks: high: \(self.env.player.numHighTracks), low: \(self.env.player.numLowTracks), mid: \(self.env.player.numMidTracks)")
            }
        }
        .padding(5)
    }
    
    var controllerTable: some View {
        var views: [TrackCellView] = []
        self.env.controllers.forEach { controller in
            if controller.hasLeft {
                views.append(TrackCellView(controller: controller, left: true, high: true))
                views.append(TrackCellView(controller: controller, left: true, high: false))
            }

            if controller.hasRight {
                views.append(TrackCellView(controller: controller, left: false, high: true))
                views.append(TrackCellView(controller: controller, left: false, high: false))
            }
        }
        
        return List(views) { $0 }
    }
    
    var assignButton: some View {
        Button(action: {
            self.env.player.assignTracks(to: self.env.controllers)
        }) {
            Text("2. Assign tracks to controllers")
        }
        .disabled(!self.env.player.isLoaded)
    }
    
    var convertButton: some View {
        Button(action: {
            if self.env.player.convertTracks(of: self.env.controllers) {
                self.isReady = true
            } else {
                let alert = NSAlert()
                alert.messageText = "Please assign tracks to controllers"
                alert.runModal()
            }
        }) {
            Text("3. Convert data")
        }
        .disabled(!self.env.player.isLoaded)
    }
    
    var playButton: some View {
        Button(action: {
            self.env.player.play(controllers: self.env.controllers)
        }) {
            Text("4. Play")
        }
        .disabled(!self.isReady)
    }
    
    var pauseButton: some View {
        Button(action: {
            self.env.player.pause()
        }) {
            Text("4. Stop")
        }
    }
}


struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView().environmentObject(AppEnv())
    }
}
