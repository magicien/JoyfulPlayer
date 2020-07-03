//
//  Note.swift
//  JoyfulPlayer
//
//  Created by magicien on 2020/06/21.
//  Copyright © 2020 DarkHorse. All rights reserved.
//

import JoyConSwift

private let noteToHighFrequency: [UInt8: Rumble.HighFrequency] = [
    40: .E2,
    41: .F2,
    42: .Fs2,
    43: .G2,
    44: .Gs2,
    45: .A2,
    46: .As2,
    47: .B2,
    48: .C3,
    49: .Cs3,
    50: .D3,
    51: .Ds3,
    52: .E3,
    53: .F3,
    54: .Fs3,
    55: .G3,
    56: .Gs3,
    57: .A3,
    58: .As3,
    59: .B3,
    60: .C4,
    61: .Cs4,
    62: .D4,
    63: .Ds4,
    64: .E4,
    65: .F4,
    66: .Fs4,
    67: .G4,
    68: .Gs4,
    69: .A4,
    70: .As4,
    71: .B4,
    72: .C5,
    73: .Cs5,
    74: .D5,
    75: .Ds5,
    76: .E5,
    77: .F5,
    78: .Fs5,
    79: .G5,
    80: .Gs5,
    81: .A5,
    82: .As5,
    83: .B5,
    84: .C6,
    85: .Cs6,
    86: .D6,
    87: .Ds6
]

private let noteToLowFrequency: [UInt8: Rumble.LowFrequency] = [
    28: .E1,
    29: .F1,
    30: .Fs1,
    31: .G1,
    32: .Gs1,
    33: .A1,
    34: .As1,
    35: .B1,
    36: .C2,
    37: .Cs2,
    38: .D2,
    39: .Ds2,
    40: .E2,
    41: .F2,
    42: .Fs2,
    43: .G2,
    44: .Gs2,
    45: .A2,
    46: .As2,
    47: .B2,
    48: .C3,
    49: .Cs3,
    50: .D3,
    51: .Ds3,
    52: .E3,
    53: .F3,
    54: .Fs3,
    55: .G3,
    56: .Gs3,
    57: .A3,
    58: .As3,
    59: .B3,
    60: .C4,
    61: .Cs4,
    62: .D4,
    63: .Ds4,
    64: .E4,
    65: .F4,
    66: .Fs4,
    67: .G4,
    68: .Gs4,
    69: .A4,
    70: .As4,
    71: .B4,
    72: .C5,
    73: .Cs5,
    74: .D5,
    75: .Ds5,
]

enum NoteRange {
    case TooLow
    case Low
    case Middle
    case High
    case TooHigh
    case Unknown
}

private let MinLow = 28
private let MinHigh = 40
private let MaxLow = 75
private let MaxHigh = 87

struct Note {
    var startTime: TimeInterval
    var endTime: TimeInterval
    var velocity: UInt8
    var range: NoteRange = .Unknown
    var note: UInt8 = 0 {
        didSet {
            if self.note < MinLow {
                self.range = .TooLow
            } else if self.note < MinHigh {
                self.range = .Low
            } else if self.note < MaxLow {
                self.range = .Middle
            } else if self.note < MaxHigh {
                self.range = .High
            } else {
                self.range = .TooHigh
            }
        }
    }
    
    init(startTime: TimeInterval, endTime: TimeInterval, velocity: UInt8, note: UInt8) {
        self.startTime = startTime
        self.endTime = endTime
        self.velocity = velocity
        defer {
            self.note = note
        }
    }
    
    var highNote: Rumble.HighFrequency? {
        return noteToHighFrequency[self.note]
    }
    var lowNote: Rumble.LowFrequency? {
        return noteToLowFrequency[self.note]
    }
}
