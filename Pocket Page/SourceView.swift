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
        List(notebook.sources) { source in // <-- Loop dynamically
            HStack {
                Image(systemName: source.fileType == "pdf" ? "doc.viewfinder" : "doc.text")
                Text(source.fileName)
            }
        }
    }
}


