//
//  leprocontrolApp.swift
//  leprocontrol
//
//  Created by Andrés Ferrer Camarasalta on 05/06/2026.
//

import SwiftUI

@main
struct leprocontrolApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .frame(minWidth: 680, minHeight: 520)
        }
    }
}
