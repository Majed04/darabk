//
//  darbakApp.swift
//  darbak
//
//  Created by Majed on 04/02/1447 AH.
//

import SwiftUI

@main
struct darbakApp: App {
    @StateObject var user = User()
    
    var body: some Scene {
        WindowGroup {
            Onboarding()
        }.environmentObject(user)
    }
}
