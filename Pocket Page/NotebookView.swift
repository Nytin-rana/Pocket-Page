//
//  NotebookView.swift
//  Pocket Page
//
//  Created by Nytin Rana on 05/07/26.
//

import SwiftUI

struct NotebookView: View {
    var body: some View {
        TabView {
            ChatView().tabItem { VStack{
                Image(systemName: "message").environment(\.symbolVariants,.none)
                Text("Chat").font(.caption)
            }}
            SourceView().tabItem { VStack{
                Image(systemName: "folder").environment(\.symbolVariants,.none)
                Text("Sources").font(.caption)
            }}
            ManageView().tabItem { Label("Manage", systemImage: "square.and.pencil") }
        }
    }
}

#Preview {
    NotebookView()
}
