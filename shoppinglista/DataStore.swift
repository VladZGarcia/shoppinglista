//
//  File.swift
//  shoppinglista
//
//  Created by Hugo Garcia on 2023-01-03.
//

import Foundation
import SwiftUI
//import Combine
import FirebaseFirestoreSwift

struct ItemList : Codable, Identifiable {
    @DocumentID var  id : String?
    var  itemName : String
    var  category : String = ""
    var  isChecked : Bool = false
    
}

class StoreItems : ObservableObject {
    @Published var items = [ItemList]()
}
