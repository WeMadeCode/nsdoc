//
//  ToolsViewModel.swift
//  note
//
//  Created by 倪申雷 on 2025/7/12.
//

import Foundation
import SwiftUI


class EditorViewModel: ObservableObject {
    
    @Published var mainTools: [ToolItem]

    @Published var subFontTools: [ToolItem]
    @Published var subStyleTools: [ToolItem]
    @Published var subAlignTools: [ToolItem]
    @Published var isInsertToolEnabled = false
    @Published var activeTools: [ToolType: Bool] = [:]
    @Published var selectedTextColor: String?
    @Published var selectedBackgroundColor: String?

    var isCustomKeyboardVisible: Bool {
        mainTools.first { $0.toolType == .insert }?.isSelected == true
    }
    
    init() {
        self.mainTools = [
            ToolItem(toolType: .insert, isRealTool: false),
            ToolItem(toolType: .text, isRealTool: false),
            ToolItem(toolType: .style, isRealTool: false),
            ToolItem(toolType: .left, isRealTool: false),
            ToolItem(toolType: .picture),
            ToolItem(toolType: .check),
        ]
        self.subFontTools = [
            ToolItem(toolType: .text),
            ToolItem(toolType: .h1),
            ToolItem(toolType: .h2),
            ToolItem(toolType: .h3),
            ToolItem(toolType: .check),
            ToolItem(toolType: .order),
            ToolItem(toolType: .unOrder),
        ]
        self.subStyleTools = [
            ToolItem(toolType: .bold),
            ToolItem(toolType: .italic),
            ToolItem(toolType: .underline),
            ToolItem(toolType: .strikethrough),
            ToolItem(toolType: .inlineCode),
            ToolItem(toolType: .reference),
            ToolItem(toolType: .colors),
        ]
        self.subAlignTools = [
            ToolItem(toolType: .left),
            ToolItem(toolType: .center),
            ToolItem(toolType: .right),
        ]
    }
    
    func updateSelected(activeTools: [ToolType: Bool], selectionContext: EditorSelectionContext? = nil) {
        self.activeTools = activeTools

        if let selectionContext {
            isInsertToolEnabled = !selectionContext.isInTitle
            selectedTextColor = selectionContext.textColor
            selectedBackgroundColor = selectionContext.backgroundColor
            if selectionContext.isInTitle {
                setPanel(.insert, isOpen: false)
            }
        }

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

        self.subStyleTools = self.subStyleTools.map { item in
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

    func closeCustomKeyboard() {
        setPanel(.insert, isOpen: false)
    }

    func closeAllPanels() {
        for index in mainTools.indices where mainTools[index].isRealTool == false {
            mainTools[index].isSelected = false
        }
    }

    func setPanel(_ toolType: ToolType, isOpen: Bool) {
        for index in mainTools.indices where mainTools[index].isRealTool == false {
            mainTools[index].isSelected = mainTools[index].toolType == toolType ? isOpen : false
        }
    }
    
}
