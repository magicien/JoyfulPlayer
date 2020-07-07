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
    @State var isParsed: Bool = false
    @State var keyChangeString: String = "0"
    
    var body: some View {
        VStack(alignment: .leading) {
            self.openButton
            self.fileInfoText
            self.keySettings
            self.parseButton
            self.trackInfoText
            self.assignButton
            self.controllerTable
            self.convertButton
            self.volumeSettings
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
                        self.keyChangeString = "\(self.env.player.keyChange)"
                        self.isParsed = false
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
                Text("Duration: \(minutes):\(String(format: "%02d", seconds))")
            }
        }
        .padding(5)
    }
    
    var keySettings: some View {
        HStack {
            Text("Key:")
            TextField("", text: self.$keyChangeString)
        }
    }
    
    var parseButton: some View {
        Button(action: {
            if let keyChange = Int(self.keyChangeString) {
                self.env.player.keyChange = keyChange
            }
            self.env.player.parse()
            self.isParsed = self.env.player.isParsed
        }) {
            Text("2. Parse")
        }
        .disabled(!self.env.player.isLoaded)
    }
    
    var trackInfoText: some View {
        Group {
            if self.env.player.isParsed {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Key: \(self.env.player.keyChange)")
                    Text("Num tracks: high: \(self.env.player.numHighTracks), low: \(self.env.player.numLowTracks), mid: \(self.env.player.numMidTracks)")
                }
                .padding(5)
            } else {
                EmptyView()
            }
        }
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
            Text("3. Assign tracks to controllers")
        }
        .disabled(!self.isParsed)
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
            Text("4. Convert data")
        }
        .disabled(!self.isParsed)
    }
    
    var volumeSettings: some View {
        let bind = Binding<Float>(get: {
            return self.env.player.volume
        }, set: { newValue in
            self.env.player.volume = newValue
        })
        
        return Slider(value: bind, in: 0...1) {
            Text("Volume")
        }
    }
    
    var playButton: some View {
        Button(action: {
            self.env.player.play(controllers: self.env.controllers)
        }) {
            Text("5. Play")
        }
        .disabled(!self.isReady)
    }
    
    var pauseButton: some View {
        Button(action: {
            self.env.player.pause(controllers: self.env.controllers)
        }) {
            Text("5. Stop")
        }
    }
}


struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView().environmentObject(AppEnv())
    }
}
