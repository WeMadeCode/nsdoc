//
//  HighlightableButton.swift
//  note
//
//  Created by 倪申雷 on 2025/7/12.
//
import SwiftUI

struct HighlightableButton: View {
    
    @Binding var image: Image
    @Binding var isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
              image
                .renderingMode(.original)
                .resizable()
                .frame(width: 20, height: 20)
        }
        .frame(width: 30, height: 30)
        .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
        .cornerRadius(8)
    }
}
