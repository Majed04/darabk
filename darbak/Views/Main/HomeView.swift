//
//  Home.swift
//  darbak
//
//  Created by Majed on 04/02/1447 AH.
//

import SwiftUI

struct Home: View {
    @State private var showAlert = false
    var body: some View {
        VStack(spacing: 20) {
            Text("Hello, world!").font(.largeTitle).fontWeight(.bold)
            Button("Show Alert") {
                showAlert = true
            }
            .alert("Important Message", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    
                }
            } message: {
                Text("This is a SwiftUI alert!")
            }
        }
    }
}
