//
//  ToolItem.swift
//  note
//
//  Created by 周翔 on 2026/5/26.
//

import SwiftUI


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
