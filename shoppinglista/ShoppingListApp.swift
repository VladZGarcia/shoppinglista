//
//  shoppinglistaApp.swift
//  shoppinglista
//
//  Created by Hugo Garcia on 2023-01-03.
//

import SwiftUI
import Firebase

@main
struct ShoppingListApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
