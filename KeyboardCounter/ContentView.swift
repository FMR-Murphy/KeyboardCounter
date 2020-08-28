//
//  ContentView.swift
//  KeyboardCounter
//
//  Created by Fang on 2020/8/13.
//

import SwiftUI

struct ContentView: View {
    
    @State var str: String
    var body: some View {
        
        VStack {
            Text("Hello, world!")
                .padding()
            TextField("Placeholder", text: $str)
        }
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        ContentView(str: "123")
    }
}
