//
//  ToolsViewModel.swift
//  note
//
//  Created by 倪申雷 on 2025/7/12.
//

import Foundation
import SwiftUI
//import SwiftUICore

struct ToolItem: Identifiable {
    
    var id = UUID()
    
    var toolType: ToolType
    var isSelected: Bool
    var image: Image
    var isRealTool: Bool
    
    init(toolType: ToolType, isSelected: Bool = false, isRealTool: Bool = true) {
        self.toolType = toolType
        self.isSelected = isSelected
        self.image = toolType.image
        self.isRealTool = isRealTool
    }
    
}

class EditorViewModel: ObservableObject {
    
    @Published var mainTools: [ToolItem]

    @Published var subFontTools: [ToolItem]
    @Published var subAlignTools: [ToolItem]
    
    init() {
        self.mainTools = [
            ToolItem(toolType: .text, isRealTool: false),
            ToolItem(toolType: .left, isRealTool: false),
            ToolItem(toolType: .bold),
            ToolItem(toolType: .italic),
            ToolItem(toolType: .strikethrough),
            ToolItem(toolType: .reference),
            ToolItem(toolType: .colors),
            ToolItem(toolType: .camera),
            ToolItem(toolType: .picture),
        ]
        self.subFontTools = [
            ToolItem(toolType: .text),
            ToolItem(toolType: .h1),
            ToolItem(toolType: .h2),
            ToolItem(toolType: .h3),
            ToolItem(toolType: .h4),
            ToolItem(toolType: .h5),
            ToolItem(toolType: .order),
            ToolItem(toolType: .unOrder),
            ToolItem(toolType: .check),
            ToolItem(toolType: .code),
        ]
        self.subAlignTools = [
            ToolItem(toolType: .left),
            ToolItem(toolType: .right),
            ToolItem(toolType: .center),
            ToolItem(toolType: .goLeft),
            ToolItem(toolType: .goRight),
        ]
    }
    
    func updateSelected(activeTools: [ToolType: Bool]) {
        self.mainTools = self.mainTools.map { item in
            var item = item
            if item.isRealTool {
                item.isSelected = activeTools[item.toolType] ?? false
            }
            return item
        }
        
        self.subFontTools = self.subFontTools.map { item in
            var item = item
            if item.isRealTool {
                item.isSelected = activeTools[item.toolType] ?? false
            }
            return item
        }
        
        self.subAlignTools = self.subAlignTools.map { item in
            var item = item
            if item.isRealTool {
                item.isSelected = activeTools[item.toolType] ?? false
            }
            return item
        }
    }
    
}
