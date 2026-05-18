//
//  MainContentView.swift
//  note
//
//  Created by 倪申雷 on 2025/6/23.
//

import SwiftUI

struct MainContentView: View {
    var body: some View {
        EditorView(article: nil, showsCloseButton: false)
    }
}

#Preview {
    MainContentView()
}
