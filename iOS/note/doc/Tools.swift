//
//  Tools.swift
//  note
//
//  Created by 倪申雷 on 2025/7/11.
//

// icon来源： https://iconpark.oceanengine.com/official
import SwiftUI

struct Tools: View {
    
    @Binding var javaScriptCommand: JavaScriptCommand?
    @ObservedObject var viewModel: EditorViewModel
    let isSystemKeyboardVisible: Bool
    let keyboardHeight: CGFloat
    private let mainToolbarHeight: CGFloat = 56
    private let toolbarSpacing: CGFloat = 8
    private let topPadding: CGFloat = 8

    var body: some View {
        VStack(spacing: toolbarSpacing) {
            if isPanelOpen(.text) {
                accessoryPanel(with: $viewModel.subFontTools)
            }
            if isPanelOpen(.left) {
                accessoryPanel(with: $viewModel.subAlignTools)
            }
            mainTools(with: $viewModel.mainTools)
        }
        .padding(.horizontal, 12)
        .padding(.top, topPadding)
        .padding(.bottom, 10)
        .background(.clear)
        .animation(.spring(response: 0.25, dampingFraction: 0.88), value: isPanelOpen(.insert))
        .animation(.spring(response: 0.25, dampingFraction: 0.88), value: isPanelOpen(.text))
        .animation(.spring(response: 0.25, dampingFraction: 0.88), value: isPanelOpen(.left))
    }
    
    func mainTools(with items: Binding<[ToolItem]>) -> some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items) { item in
                        let isEnabled = item.wrappedValue.toolType != .insert || viewModel.isInsertToolEnabled

                        ToolBarButton(item: item, isEnabled: isEnabled) {
                            let itemValue = item.wrappedValue
                            guard isEnabled else {
                                return
                            }

                            if itemValue.isRealTool == false {
                                togglePanel(item)
                            } else {
                                guard !itemValue.toolType.jsMethodName.isEmpty else {
                                    return
                                }
                                runTool(itemValue)
                            }
                        }
                        if item.wrappedValue.toolType == .insert || item.wrappedValue.toolType == .left {
                            ToolDivider()
                        }
                    }
                }
                .padding(.leading, 8)
            }
        
            Spacer()
            
            Button {
                UIApplication.shared.endEditing()
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 19, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .foregroundStyle(Color(.systemBlue))
            }
            .buttonStyle(.plain)
            .background(Color(.secondarySystemFill), in: Circle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(height: mainToolbarHeight)
        .background(
            Capsule()
                .fill(Color(.systemBackground).opacity(0.96))
                .background(.regularMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color(.separator).opacity(0.28), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 6)
        )
    }
    
    func accessoryPanel(with items: Binding<[ToolItem]>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            subTools(with: items)
                .padding(.horizontal, 18)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    func subTools(with items: Binding<[ToolItem]>) -> some View {
        HStack(spacing: 10) {
            ForEach(items) { item in
                ToolBarButton(item: item) {
                    let itemValue = item.wrappedValue
                    guard !itemValue.toolType.jsMethodName.isEmpty else {
                        return
                    }
                    runTool(itemValue)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(.systemBackground).opacity(0.96))
                .background(.regularMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color(.separator).opacity(0.26), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.09), radius: 12, x: 0, y: 5)
        )
    }

    private func togglePanel(_ item: Binding<ToolItem>) {
        let selectedID = item.wrappedValue.id
        let toolType = item.wrappedValue.toolType
        let willOpen = !item.wrappedValue.isSelected

        if toolType == .insert, willOpen {
            viewModel.setPanel(.insert, isOpen: true)
            javaScriptCommand = JavaScriptCommand(methodName: "focus", completion: nil)
            return
        }

        if toolType == .insert, !willOpen {
            viewModel.setPanel(.insert, isOpen: false)
            javaScriptCommand = JavaScriptCommand(methodName: "focus", completion: nil)
            return
        }

        for index in viewModel.mainTools.indices where viewModel.mainTools[index].isRealTool == false {
            viewModel.mainTools[index].isSelected = viewModel.mainTools[index].id == selectedID ? willOpen : false
        }
    }

    private func isPanelOpen(_ toolType: ToolType) -> Bool {
        viewModel.mainTools.first { $0.toolType == toolType }?.isSelected == true
    }

    private func runTool(_ item: ToolItem) {
        javaScriptCommand = JavaScriptCommand(
            methodName: item.toolType.jsMethodName,
            params: item.toolType.jsParams,
            completion: nil
        )
    }

}

private struct ToolBarButton: View {
    @Binding var item: ToolItem
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                buttonContent

                if !item.isRealTool && item.toolType != .insert {
                    Image(systemName: item.isSelected ? "chevron.down" : "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                        .opacity(0.72)
                }
            }
            .frame(width: buttonWidth, height: 38)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, item.toolType == .style ? 2 : 0)
            .background(selectedBackground)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private var foregroundColor: Color {
        if !isEnabled {
            return Color(.tertiaryLabel)
        }

        return item.isSelected ? Color(.systemBlue) : Color(.label).opacity(0.82)
    }

    private var buttonWidth: CGFloat {
        switch item.toolType {
        case .text where !item.isRealTool:
            return 56
        case .style:
            return 46
        default:
            return 42
        }
    }

    @ViewBuilder
    private var selectedBackground: some View {
        if item.isSelected && isEnabled {
            Capsule()
                .fill(Color(.systemBlue).opacity(item.toolType == .text && !item.isRealTool ? 0.14 : 0.12))
                .overlay(
                    Capsule()
                        .stroke(Color(.systemBlue).opacity(0.16), lineWidth: 1)
                )
        } else {
            Capsule()
                .fill(Color.clear)
        }
    }

    @ViewBuilder
    private var buttonContent: some View {
        switch item.toolType {
        case .insert:
            Image(systemName: "plus.circle")
                .font(.system(size: 24, weight: .semibold))
                .frame(width: 24, height: 24)
        case .text:
            Text("T")
                .font(.system(size: item.isRealTool ? 28 : 27, weight: .semibold, design: .serif))
                .frame(width: 24, height: 24)
        case .style:
            Text("Aa")
                .font(.system(size: 23, weight: .medium))
                .fixedSize()
        case .h1:
            headingLabel("H1")
        case .h2:
            headingLabel("H2")
        case .h3:
            headingLabel("H3")
        case .order:
            orderedListIcon
        case .mention:
            Image(systemName: "at")
                .font(.system(size: 24, weight: .semibold))
                .frame(width: 24, height: 24)
        default:
            item.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
        }
    }

    private func headingLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 23, weight: .medium))
            .fixedSize()
    }

    private var orderedListIcon: some View {
        HStack(spacing: 3) {
            Text("1\n2\n3")
                .font(.system(size: 9, weight: .bold))
                .lineSpacing(-1)
                .multilineTextAlignment(.trailing)
            VStack(alignment: .leading, spacing: 5) {
                RoundedRectangle(cornerRadius: 1)
                    .frame(width: 17, height: 2)
                RoundedRectangle(cornerRadius: 1)
                    .frame(width: 17, height: 2)
                RoundedRectangle(cornerRadius: 1)
                    .frame(width: 17, height: 2)
            }
        }
        .frame(width: 24, height: 24)
    }
}

private struct InsertBlock: Identifiable {
    let id = UUID()
    let toolType: ToolType
    let title: String
    let iconTitle: String?
    let systemImage: String?

    static let defaultBlocks: [InsertBlock] = [
        InsertBlock(toolType: .text, title: "文本", iconTitle: "T", systemImage: nil),
        InsertBlock(toolType: .h1, title: "标题 1", iconTitle: "H1", systemImage: nil),
        InsertBlock(toolType: .h2, title: "标题 2", iconTitle: "H2", systemImage: nil),
        InsertBlock(toolType: .h3, title: "标题 3", iconTitle: "H3", systemImage: nil),
        InsertBlock(toolType: .h4, title: "标题 4", iconTitle: "H4", systemImage: nil),
        InsertBlock(toolType: .unOrder, title: "项目符号列表", iconTitle: nil, systemImage: "list.bullet"),
        InsertBlock(toolType: .order, title: "有序列表", iconTitle: nil, systemImage: "list.number"),
        InsertBlock(toolType: .check, title: "待办清单", iconTitle: nil, systemImage: "checklist"),
        InsertBlock(toolType: .foldList, title: "折叠列表", iconTitle: nil, systemImage: "list.triangle"),
        InsertBlock(toolType: .table, title: "表格", iconTitle: nil, systemImage: "tablecells"),
        InsertBlock(toolType: .page, title: "页面", iconTitle: nil, systemImage: "doc.text"),
    ]
}

private struct InsertBlockButton: View {
    let block: InsertBlock
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                icon
                    .foregroundStyle(Color(.tertiaryLabel))
                    .frame(width: 34, height: 34)

                Text(block.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(.label))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.18), radius: 0, x: 0, y: 1)
                    .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var icon: some View {
        if let iconTitle = block.iconTitle {
            Text(iconTitle)
                .font(.system(size: 24, weight: .semibold, design: .serif))
        } else if let systemImage = block.systemImage {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .semibold))
        }
    }
}

private struct ToolDivider: View {
    var body: some View {
        Divider()
            .frame(height: 26)
            .opacity(0.55)
            .padding(.horizontal, 2)
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
}
