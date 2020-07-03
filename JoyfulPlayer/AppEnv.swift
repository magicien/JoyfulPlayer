//
//  AppEnv.swift
//  JoyfulPlayer
//
//  Created by magicien on 2020/06/28.
//  Copyright © 2020 DarkHorse. All rights reserved.
//

import JoyConSwift
import SwiftUI

class AppEnv: ObservableObject {
    let manager = JoyConManager()
    let player = Player()
    @Published var controllers: [Controller] = []
    @Published var isPlaying: Bool = false
}
