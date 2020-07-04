//
//  Player.swift
//  JoyfulPlayer
//
//  Created by magicien on 2020/06/21.
//  Copyright © 2020 DarkHorse. All rights reserved.
//

import MidiParser
import JoyConSwift
import UserNotifications

class Subtrack: Identifiable, Hashable, ObservableObject {
    var id = UUID()
    var range: NoteRange = .Unknown
    var notes: [Note] = []
    var name: String = ""
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    static func == (lhs: Subtrack, rhs: Subtrack) -> Bool {
        lhs.id == rhs.id
    }
}

struct NoteEvent {
    var time: TimeInterval
    var note: Note
    var isLeft: Bool
    var isHigh: Bool
    var isStart: Bool
}

struct RumbleEvent {
    var time: TimeInterval
    var leftLowFreq: Rumble.LowFrequency
    var leftLowAmp: UInt8
    var leftHighFreq: Rumble.HighFrequency
    var leftHighAmp: UInt8
    var rightLowFreq: Rumble.LowFrequency
    var rightLowAmp: UInt8
    var rightHighFreq: Rumble.HighFrequency
    var rightHighAmp: UInt8
    
    func send(to controller: Controller) {
        controller.controller.sendRumbleData(
            leftLowFreq: self.leftLowFreq,
            leftLowAmp: self.leftLowAmp,
            leftHighFreq: self.leftHighFreq,
            leftHighAmp: self.leftHighAmp,
            rightLowFreq: self.rightLowFreq,
            rightLowAmp: self.rightLowAmp,
            rightHighFreq: self.rightHighFreq,
            rightHighAmp: self.rightHighAmp
        )
    }
}

class Player {
    let midi: MidiData
    var isLoaded: Bool
    var timer: Timer?
    var subtimers: [Timer] = []
    
    var tracks: [[Subtrack]]
    var duration: Double {
        if !self.isLoaded {
            return 0
        }

        let tempo = 60.0 / (self.midi.infoDictionary[.tempo] as? Double ?? 60.0)
        let durations = self.midi.noteTracks.map {
            $0.offsetTime + $0.trackLength
        }
        return (durations.max() ?? 0) * tempo
    }
    var numHighTracks: Int {
        let highTracks = self.tracks.map { subtracks in
            subtracks.filter { $0.range == .High }.count
        }
        return highTracks.reduce(0, +)
    }
    var numLowTracks: Int {
        let highTracks = self.tracks.map { subtracks in
            subtracks.filter { $0.range == .Low }.count
        }
        return highTracks.reduce(0, +)
    }
    var numMidTracks: Int {
        let highTracks = self.tracks.map { subtracks in
            subtracks.filter { $0.range == .Middle }.count
        }
        return highTracks.reduce(0, +)
    }

    init() {
        self.midi = MidiData()
        self.isLoaded = false
        self.tracks = []
    }
    
    func load(url: URL) throws {
        let data = try Data(contentsOf: url)
        self.midi.load(data: data)
        self.parse()
        self.isLoaded = true
    }
    
    func parse() {
        self.tracks = []
        let tempo = 60.0 / (self.midi.infoDictionary[.tempo] as? Double ?? 60.0)
        
        self.midi.noteTracks.forEach { track in
            var subtracks: [Subtrack] = []
            
            track.notes.forEach {
                let startTime = ($0.timeStamp + track.offsetTime) * tempo
                let endTime = startTime + Double($0.duration) * tempo
                
                let note = Note(
                    startTime: startTime,
                    endTime: endTime,
                    velocity: $0.velocity,
                    note: $0.note
                )
                if note.range == .Unknown || note.range == .TooHigh || note.range == .TooLow {
                    return
                }
                
                if note.range == .Middle {
                    if let index = subtracks.firstIndex(where: { subtrack in
                        guard let end = subtrack.notes.last?.endTime else { return false }
                        return end <= startTime
                    }) {
                        subtracks[index].notes.append(note)
                    } else {
                        let newSub = Subtrack()
                        newSub.range = .Middle
                        newSub.notes = [note]
                        subtracks.append(newSub)
                    }
                } else if note.range == .Low {
                    if let index = subtracks.firstIndex(where: { subtrack in
                        guard subtrack.range == .Low else { return false }
                        guard let end = subtrack.notes.last?.endTime else { return false }
                        return end <= startTime
                    }) {
                        subtracks[index].notes.append(note)
                    } else if let index = subtracks.firstIndex(where: { subtrack in
                        guard let end = subtrack.notes.last?.endTime else { return false }
                        return end <= startTime
                    }) {
                        subtracks[index].notes.append(note)
                        subtracks[index].range = .Low
                    } else {
                        let newSub = Subtrack()
                        newSub.range = .Low
                        newSub.notes = [note]

                        subtracks.append(newSub)
                    }
                } else if note.range == .High {
                    if let index = subtracks.firstIndex(where: { subtrack in
                        guard subtrack.range == .High else { return false }
                        guard let end = subtrack.notes.last?.endTime else { return false }
                        return end <= startTime
                    }) {
                        subtracks[index].notes.append(note)
                    } else if let index = subtracks.firstIndex(where: { subtrack in
                        guard let end = subtrack.notes.last?.endTime else { return false }
                        return end <= startTime
                    }) {
                        subtracks[index].notes.append(note)
                        subtracks[index].range = .High
                    } else {
                        let newSub = Subtrack()
                        newSub.range = .High
                        newSub.notes = [note]

                        subtracks.append(newSub)
                    }
                }
            }
            
            var numHigh = 0
            var numLow = 0
            var numMid = 0

            let trackIndex = (self.midi.noteTracks.firstIndex { $0 == track } ?? -1) + 1
            let trackName = track.trackName != "" ? track.trackName : "Track \(trackIndex)"
            for i in 0..<subtracks.count {
                if subtracks[i].range == .High {
                    numHigh += 1
                    subtracks[i].name = "\(trackName) - high \(numHigh)"
                } else if subtracks[i].range == .Low {
                    numLow += 1
                    subtracks[i].name = "\(trackName) - low \(numLow)"
                } else if subtracks[i].range == .Middle {
                    numMid += 1
                    subtracks[i].name = "\(trackName) - mid \(numMid)"
                }
            }
            
            self.tracks.append(subtracks)
        }
    }
    
    func assignTracks(to controllers: [Controller]) {
        controllers.forEach {
            $0.leftHighTrack = nil
            $0.leftLowTrack = nil
            $0.rightHighTrack = nil
            $0.rightLowTrack = nil
        }
        
        var tracks: [Subtrack] = []
        self.tracks.forEach { tracks.append(contentsOf: $0) }
        
        var highTracks: [Subtrack] = tracks.filter { $0.range == .High }.reversed()
        var lowTracks: [Subtrack] = tracks.filter { $0.range == .Low }.reversed()
        var midTracks: [Subtrack] = tracks.filter { $0.range == .Middle }.reversed()

        controllers.forEach { controller in
            if controller.hasLeft {
                if controller.leftHighTrack == nil {
                    controller.leftHighTrack = highTracks.popLast()
                }
                if controller.leftLowTrack == nil {
                    controller.leftLowTrack = lowTracks.popLast()
                }
            }
            if controller.hasRight {
                if controller.rightHighTrack == nil {
                    controller.rightHighTrack = highTracks.popLast()
                }
                if controller.rightLowTrack == nil {
                    controller.rightLowTrack = lowTracks.popLast()
                }
            }
        }
        
        controllers.forEach { controller in
            if controller.hasLeft {
                if controller.leftHighTrack == nil {
                    controller.leftHighTrack = midTracks.popLast()
                }
                if controller.leftLowTrack == nil {
                    controller.leftLowTrack = midTracks.popLast()
                }
            }
            if controller.hasRight {
                if controller.rightHighTrack == nil {
                    controller.rightHighTrack = midTracks.popLast()
                }
                if controller.rightLowTrack == nil {
                    controller.rightLowTrack = midTracks.popLast()
                }
            }
        }
    }
    
    func convertToEvents(from notes: [Note], left: Bool, high: Bool) -> [NoteEvent] {
        let minGap = 0.1
        var events: [NoteEvent] = []
        
        for i in 0..<notes.count-1 {
            let note = notes[i]
            events.append(
                NoteEvent(
                    time: note.startTime,
                    note: note,
                    isLeft: left,
                    isHigh: high,
                    isStart: true
                )
            )
            let next = notes[i+1]
            if note.endTime < next.startTime - minGap {
                events.append(
                    NoteEvent(
                        time: note.endTime,
                        note: note,
                        isLeft: left,
                        isHigh: high,
                        isStart: false
                    )
                )
            }
        }
        
        if let last = notes.last {
            events.append(
                NoteEvent(
                    time: last.startTime,
                    note: last,
                    isLeft: left,
                    isHigh: high,
                    isStart: true
                )
            )
            events.append(
                NoteEvent(
                    time: last.endTime,
                    note: last,
                    isLeft: left,
                    isHigh: high,
                    isStart: false
                )
            )
        }
        
        return events
    }
    
    func convertTracksToNoteEvents(of controller: Controller) -> [NoteEvent] {
        var events: [NoteEvent] = []
        
        if let notes = controller.leftHighTrack?.notes.sorted(by: { $0.startTime < $1.startTime }) ?? nil {
            events.append(contentsOf: self.convertToEvents(from: notes, left: true, high: true))
        }
        if let notes = controller.leftLowTrack?.notes.sorted(by: { $0.startTime < $1.startTime }) ?? nil {
            events.append(contentsOf: self.convertToEvents(from: notes, left: true, high: false))
        }
        if let notes = controller.rightHighTrack?.notes.sorted(by: { $0.startTime < $1.startTime }) ?? nil {
            events.append(contentsOf: self.convertToEvents(from: notes, left: false, high: true))
        }
        if let notes = controller.rightLowTrack?.notes.sorted(by: { $0.startTime < $1.startTime }) ?? nil {
            events.append(contentsOf: self.convertToEvents(from: notes, left: false, high: false))
        }

        events.sort { $0.time < $1.time }
        
        return events
    }
    
    func convertTracks(of controller: Controller) {
        let noteEvents = self.convertTracksToNoteEvents(of: controller)
        var events: [RumbleEvent] = []
        var prev = RumbleEvent(
            time: -1,
            leftLowFreq: .A1,
            leftLowAmp: 0,
            leftHighFreq: .A2,
            leftHighAmp: 0,
            rightLowFreq: .A1,
            rightLowAmp: 0,
            rightHighFreq: .A2,
            rightHighAmp: 0
        )

        let velocityToAmp = 100.0 / 127.0
        noteEvents.forEach { note in
            var event = prev
            event.time = note.time
            let amp: UInt8 = note.isStart ? UInt8(Double(note.note.velocity) * velocityToAmp) : 0
                
            if note.isLeft {
                if note.isHigh {
                    event.leftHighFreq = note.note.highNote ?? .A2
                    event.leftHighAmp = amp
                } else {
                    event.leftLowFreq = note.note.lowNote ?? .A1
                    event.leftLowAmp = amp
                }
            } else {
                if note.isHigh {
                    event.rightHighFreq = note.note.highNote ?? .A2
                    event.rightHighAmp = amp
                } else {
                    event.rightLowFreq = note.note.lowNote ?? .A1
                    event.rightLowAmp = amp
                }
            }

            events.append(event)
            prev = event
        }
        
        controller.events = events
    }
    
    func convertTracks(of controllers: [Controller]) -> Bool {
        let assignedController = controllers.first {
            $0.leftLowTrack != nil
                || $0.leftHighTrack != nil
                || $0.rightLowTrack != nil
                || $0.rightHighTrack != nil
        }
        if assignedController == nil {
            return false
        }
        
        controllers.forEach { self.convertTracks(of: $0) }
        return true
    }
    
    func play(controllers: [Controller]) {
        let durations = controllers.map { $0.events.last?.time ?? 0 }
        let duration = durations.max() ?? 0

        let interval: TimeInterval = 2.0
        var currentTime: TimeInterval = 0.0
        var indices: [Int] = [Int](repeating: 0, count: controllers.count)

        self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            if currentTime > duration {
                self?.pause(controllers: controllers)
                return
            }

            let nextTime = currentTime + interval
            self?.subtimers.removeAll()
            for i in 0..<controllers.count {
                let controller = controllers[i]
                let rumbleData = controller.events
                var index = indices[i]
                while index < rumbleData.count && rumbleData[index].time < nextTime {
                    let data = rumbleData[index]
                    let time = data.time - currentTime
                    let subtimer = Timer.scheduledTimer(withTimeInterval: time, repeats: false) { _ in
                        data.send(to: controller)
                    }
                    self?.subtimers.append(subtimer)
                    index += 1
                }
                indices[i] = index
            }
                        
            currentTime = nextTime
        }
        
        NotificationCenter.default.post(name: .didStartPlaying, object: nil)
    }
    
    func pause(controllers: [Controller]) {
        guard let timer  = self.timer else { return }
        timer.invalidate()
        self.timer = nil
        self.subtimers.forEach { $0.invalidate() }
        self.subtimers.removeAll()
        
        controllers.forEach {
            $0.stopRumble()
        }
        
        NotificationCenter.default.post(name: .didStopPlaying, object: nil)
    }
}
