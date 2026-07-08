//
//  SourceView.swift
//  Pocket Page
//
//  Created by Nytin Rana on 05/07/26.
//

import SwiftUI

struct SourceView: View {
    var notebook: Notebook

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            List(notebook.sources) { source in
                HStack {
                    Image(systemName: source.fileType == "pdf" ? "doc.viewfinder" : "doc.text")
                        .foregroundColor(.white.opacity(0.7))
                    Text(source.fileName)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.white.opacity(0.03))
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
        }
    }
}

