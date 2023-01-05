//
//  ContentView.swift
//  shoppinglista
//
//  Created by Hugo Garcia on 2023-01-03.
//

import SwiftUI
import Firebase

struct ContentView: View {
    let db = Firestore.firestore()
    
    @ObservedObject var storeItems = StoreItems()
    @State var newItem : String = ""
    
    var searchBar : some View {
        HStack {
            TextField("Enter in new item", text: self.$newItem)
            Button(action: self.addNewItem, label: {
                Text("Add New")
            })
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                searchBar.padding()
                List{
                    ForEach(storeItems.items) {
                        item in
                        HStack {
                            Text(item.itemName)
                            Spacer()
                            Button(action: {
                                if let id = item.id {
                                    db.collection("items").document(id).updateData(["isChecked": !item.isChecked])
                                }
                            }) {
                                Image(systemName: item.isChecked ? "checkmark.square" : "square")
                            }
                        }
                    }.onMove(perform: self.move)
                        .onDelete() { indexSet in
                            for index in indexSet {
                                let item = storeItems.items[index]
                                if let id = item.id {
                                    db.collection("items").document(id).delete()
                                }
                            }
                        }
                }.onAppear() {
                    listenToFirestore()
                }
                .navigationBarTitle("ShoppingList")
                    .navigationBarItems(trailing: EditButton())
            }
            .padding()
        }
    }
    
    func addNewItem() {
        saveToFirestore(newItem)
        self.newItem = ""
    }
    
    func saveToFirestore(_ newItem: String) {
        let item = ItemList(itemName: newItem)
        
        do {
            _ = try db.collection("items").addDocument(from: item)
        } catch {
            print("Error savin to DB")
        }
    }
    func listenToFirestore() {
        db.collection("items").addSnapshotListener { snapshot, err in
            guard let snapshot = snapshot else {return}
            
            if let err = err {
                print("Error getting document \(err)")
            } else {
                storeItems.items.removeAll()
                for document in snapshot.documents {
                    let result = Result{
                        try document.data(as: ItemList.self)
                    }
                    switch result {
                    case .success(let item) :
                        storeItems.items.append(item)
                    case .failure(let error) :
                        print("Error decoding item: \(error)")
                    }
                }
            }
        }
    }
    
    func move(from source : IndexSet, to destination : Int) {
        storeItems.items.move(fromOffsets: source, toOffset: destination)
    }
    
    func delete(at offsets : IndexSet) {
        storeItems.items.remove(atOffsets: offsets)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}