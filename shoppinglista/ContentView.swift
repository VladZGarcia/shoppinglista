//
//  ContentView.swift
//  shoppinglista
//
//  Created by Hugo Garcia on 2023-01-03.
//

import SwiftUI
import Firebase
import FirebaseAuth

// 1. förbättra strukturen genom att länna över shoppinglistan (items)
// i ett oservable object
//
// 2. användaren kan välja att skapa konto i en inställnings sida.

struct ContentView: View {
    @State var signedIn = false
    
    var body: some View {
        if !signedIn {
            SigningInView(signedIn: $signedIn)
        } else {
            ShoppingListView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct SigningInView: View {
    @Binding var signedIn : Bool
    var body: some View {
        Text("Signing In")
            .onAppear() {
                Auth.auth().signInAnonymously { authResult, error in
                    if let error = error {
                        print("error signing in \(error)")
                    } else {
                        print("Signed in \(Auth.auth().currentUser?.uid)")
                        signedIn = true
                    }
                }
            }
    }
}

struct ShoppingListView: View {
    let db = Firestore.firestore()
    @State var newItem : String = ""
    @ObservedObject var storeItems = StoreItems()
    
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
                        ItemRowView(item: item)
                    }.onMove(perform: move)
                        .onDelete() { indexSet in
                            for index in indexSet {
                                let item = storeItems.items[index]
                                if let id = item.id,
                                   let user = Auth.auth().currentUser
                                {
                                    db.collection("users").document(user.uid).collection("items").document(id).delete()
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
        
        func move(from source : IndexSet, to destination : Int) {
            storeItems.items.move(fromOffsets: source, toOffset: destination)
        }
        
        func listenToFirestore() {
            guard let user = Auth.auth().currentUser else {return}
            
            db.collection("users").document(user.uid).collection("items").addSnapshotListener { snapshot, err in
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
    
    
    func saveToFirestore(_ newItem: String) {
        let item = ItemList(itemName: newItem)
        guard let user = Auth.auth().currentUser else {return}
        
        do {
            _ = try db.collection("users").document(user.uid).collection("items").addDocument(from: item)
        } catch {
            print("Error savin to DB")
        }
    }
    
    func addNewItem() {
        saveToFirestore(newItem)
        self.newItem = ""
    }
}

struct ItemRowView: View {
    let db = Firestore.firestore()
    let item : ItemList
    
    var body: some View {
        HStack {
            Text(item.itemName)
            Spacer()
            Button(action: {
                if let id = item.id,
                   let user = Auth.auth().currentUser
                {
                    db.collection("users").document(user.uid)
                        .collection("items").document(id).updateData(["isChecked": !item.isChecked])
                }
            }) {
                Image(systemName: item.isChecked ? "checkmark.square" : "square")
            }
        }
    }
}
