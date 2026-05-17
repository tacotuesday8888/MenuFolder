//
//  MenuFolderApp.swift
//  MenuFolder
//
//  Created by Langqi Zhao on 5/16/26.
//

import SwiftUI

@main
struct MenuFolderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
