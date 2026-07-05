//
//  ManageView.swift
//  Pocket Page
//
//  Created by Nytin Rana on 05/07/26.
//

import SwiftUI

struct ManageView: View {
    @State private var showingCreateNotebook: Bool = false
    var body: some View {
        VStack {
            
            
            List {
                HStack {
                    Text("Source.pdf")
                    Spacer()
                    Image(systemName: "trash").foregroundStyle(Color.red)
                }
                HStack {
                    Text("Source.txt")
                    Spacer()
                    Image(systemName: "trash").foregroundStyle(Color.red)
                }
                HStack {
                    Text("Source.md")
                    Spacer()
                    Image(systemName: "trash").foregroundStyle(Color.red)
                }
                
            }
            
            Button(action: {
                showingCreateNotebook = true
                print("btn pressed")
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                    Text("Create New")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .frame(height: 56)
                .contentShape(Capsule())
            }
            .liquidGlassCapsule()
            .padding(24)
            .sheet(isPresented: $showingCreateNotebook) {
                CreateNotebookBottomSheet(isPresented: $showingCreateNotebook)
                
                
                
                
                
            }
        }
    }
}

#Preview {
    ManageView()
}
