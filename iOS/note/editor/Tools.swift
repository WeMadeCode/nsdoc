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
    let onPresentColorPanel: () -> Void
    private let mainToolbarHeight: CGFloat = 56
    private let toolbarSpacing: CGFloat = 8
    private let topPadding: CGFloat = 8

    var body: some View {
        VStack(spacing: toolbarSpacing) {
            if isPanelOpen(.text) {
                accessoryPanel(with: $viewModel.subFontTools)
            }
            if isPanelOpen(.style) {
                styleAccessoryPanel(with: $viewModel.subStyleTools)
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
                                let shouldAnimatePanel = isSystemKeyboardVisible && !viewModel.isCustomKeyboardVisible && itemValue.toolType != .insert
                                togglePanel(item, animated: shouldAnimatePanel)
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
        .transition(.opacity)
    }

    func styleAccessoryPanel(with items: Binding<[ToolItem]>) -> some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                subTools(with: Binding(
                    get: { items.wrappedValue.filter { $0.toolType != .colors } },
                    set: { updatedItems in
                        for updatedItem in updatedItems {
                            if let index = items.wrappedValue.firstIndex(where: { $0.id == updatedItem.id }) {
                                items.wrappedValue[index] = updatedItem
                            }
                        }
                    }
                ), usesContainer: false)
                .padding(.leading, 12)
            }

            ToolDivider()

            TextColorPopupButton {
                onPresentColorPanel()
            }
            .padding(.trailing, 10)
        }
        .padding(.vertical, 8)
        .background(secondaryToolbarBackground)
        .padding(.horizontal, 18)
        .transition(.opacity)
    }

    func subTools(with items: Binding<[ToolItem]>, usesContainer: Bool = true) -> some View {
        HStack(spacing: 10) {
            ForEach(items) { item in
                if item.wrappedValue.toolType == .colors {
                    TextColorPopupButton {
                        onPresentColorPanel()
                    }
                } else {
                    ToolBarButton(item: item) {
                        let itemValue = item.wrappedValue
                        guard !itemValue.toolType.jsMethodName.isEmpty else {
                            return
                        }
                        runTool(itemValue)
                    }
                }
            }
        }
        .padding(.horizontal, usesContainer ? 12 : 0)
        .padding(.vertical, usesContainer ? 8 : 0)
        .background {
            if usesContainer {
                secondaryToolbarBackground
            }
        }
    }

    private var secondaryToolbarBackground: some View {
        Capsule()
            .fill(Color(.systemBackground).opacity(0.96))
            .background(.regularMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(.separator).opacity(0.28), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 6)
    }

    private func togglePanel(_ item: Binding<ToolItem>, animated: Bool) {
        if animated {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.88)) {
                updatePanelSelection(item)
            }
        } else {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                updatePanelSelection(item)
            }
        }
    }

    private func updatePanelSelection(_ item: Binding<ToolItem>) {
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
        runCommand(methodName: item.toolType.jsMethodName, params: item.toolType.jsParams)
    }

    private func runCommand(methodName: String, params: [String: Any]? = nil) {
        javaScriptCommand = JavaScriptCommand(
            methodName: methodName,
            params: params,
            completion: nil
        )
    }

}

private struct TextColorPopupButton: View {
    let presentPanel: () -> Void
    
    var body: some View {
        Button(action: presentPanel) {
            HStack(spacing: 2) {
                Text("A")
                    .font(.system(size: 28, weight: .regular))
                    .overlay(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(.systemRed))
                            .frame(width: 20, height: 3)
                            .offset(y: 3)
                    }
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
            }
            .frame(width: 42, height: 38)
            .foregroundStyle(Color(.label).opacity(0.82))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ColorAndHighlightSheet: View {
    let selectedTextColor: String?
    let selectedBackgroundColor: String?
    let onDismiss: () -> Void
    let onSetTextColor: (String) -> Void
    let onSetBackgroundColor: (String) -> Void
    let onUnsetBackgroundColor: () -> Void
    let onReset: () -> Void

    private let textColors: [(name: String, value: String, color: Color)] = [
        ("黑色", "#24292F", Color(.label)),
        ("灰色", "#8C959F", Color(.systemGray)),
        ("红色", "#D1242F", .red),
        ("橙色", "#BC4C00", .orange),
        ("黄色", "#9A6700", .yellow),
        ("绿色", "#1A7F37", .green),
        ("蓝色", "#0969DA", .blue),
        ("紫色", "#8250DF", .purple),
    ]

    private let backgroundColors: [(name: String, value: String?, color: Color)] = [
        ("无", nil, .white),
        ("浅灰", "#EAEFF3", Color(.systemGray6)),
        ("浅红", "#FFD8D8", Color(red: 1, green: 0.72, blue: 0.72)),
        ("浅橙", "#FFDFB5", Color(red: 1, green: 0.84, blue: 0.65)),
        ("浅黄", "#FFF68A", Color(red: 1, green: 0.97, blue: 0.50)),
        ("浅绿", "#C8F0BE", Color(red: 0.78, green: 0.94, blue: 0.73)),
        ("浅蓝", "#CCDAF7", Color(red: 0.78, green: 0.85, blue: 0.97)),
        ("浅紫", "#DAC3F5", Color(red: 0.86, green: 0.76, blue: 0.96)),
        ("白色", "#F6F8FA", Color(.systemGray6)),
        ("灰色", "#B8BDC2", Color(.systemGray3)),
        ("红色", "#FF6262", Color(red: 1, green: 0.36, blue: 0.36)),
        ("橙色", "#FFA53A", Color(red: 1, green: 0.62, blue: 0.20)),
        ("黄色", "#FFE81A", Color(red: 1, green: 0.90, blue: 0.04)),
        ("绿色", "#5BCC50", Color(red: 0.35, green: 0.80, blue: 0.31)),
        ("蓝色", "#99B8F5", Color(red: 0.58, green: 0.70, blue: 0.95)),
        ("紫色", "#BD9AF0", Color(red: 0.73, green: 0.58, blue: 0.92)),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 12) {
                    colorSectionTitle("字体颜色")
                    textColorGrid
                }

                VStack(alignment: .leading, spacing: 12) {
                    colorSectionTitle("背景颜色")
                    backgroundColorGrid
                }

                Button(action: onReset) {
                    Text("恢复默认")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color(.label))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color(.separator).opacity(0.65), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 18)

            Spacer(minLength: 0)
        }
        .background(Color(.systemBackground))
    }

    private var header: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(Color(.label))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("颜色和高亮")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color(.label))

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 14)
        .frame(height: 56)
    }

    private func colorSectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Color(.label))
    }

    private var textColorGrid: some View {
        HStack(spacing: 0) {
            ForEach(textColors, id: \.value) { item in
                Button {
                    onSetTextColor(item.value)
                } label: {
                    Text("A")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(item.color)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(.secondarySystemBackground))
                        .overlay(selectionBorder(isSelected: selectedTextColor == item.value))
                        .overlay(alignment: .trailing) {
                            if item.value != textColors.last?.value {
                                Divider()
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var backgroundColorGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { column in
                        let item = backgroundColors[row * 8 + column]
                        Button {
                            if let value = item.value {
                                onSetBackgroundColor(value)
                            } else {
                                onUnsetBackgroundColor()
                            }
                        } label: {
                            ZStack {
                                item.color
                                if item.value == nil {
                                    diagonalLine
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .overlay(selectionBorder(isSelected: selectedBackgroundColor == item.value))
                            .overlay(alignment: .trailing) {
                                if column < 7 {
                                    Divider()
                                }
                            }
                            .overlay(alignment: .bottom) {
                                if row == 0 {
                                    Divider()
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func selectionBorder(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .stroke(isSelected ? Color(.systemBlue) : Color.clear, lineWidth: 4)
            .padding(2.5)
    }

    private var diagonalLine: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
            }
            .stroke(Color(.separator), lineWidth: 1)
        }
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

                if !item.isRealTool && item.toolType != .insert && item.toolType != .style {
                    Image(systemName: item.isSelected ? "chevron.down" : "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                        .opacity(item.isSelected ? 0.82 : 0.68)
                }
            }
            .frame(width: buttonWidth, height: 36)
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
        case .left where !item.isRealTool:
            return 58
        case .style:
            return item.isRealTool ? 46 : 52
        default:
            return 42
        }
    }

    @ViewBuilder
    private var selectedBackground: some View {
        if item.isSelected && isEnabled {
            Capsule()
                .fill(Color(.systemBlue).opacity(isPanelButton ? 0.10 : 0.12))
                .overlay(
                    Capsule()
                        .stroke(Color(.systemBlue).opacity(isPanelButton ? 0.20 : 0.16), lineWidth: 1)
                )
                .shadow(color: Color(.systemBlue).opacity(isPanelButton ? 0.08 : 0), radius: 5, x: 0, y: 2)
        } else {
            Capsule()
                .fill(Color.clear)
        }
    }

    private var isPanelButton: Bool {
        !item.isRealTool
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
        case .bold:
            Text("B")
                .font(.system(size: 28, weight: .semibold))
                .frame(width: 24, height: 24)
        case .italic:
            Text("I")
                .font(.system(size: 28, weight: .regular))
                .italic()
                .frame(width: 24, height: 24)
        case .underline:
            Text("U")
                .font(.system(size: 28, weight: .regular))
                .underline()
                .frame(width: 24, height: 24)
        case .strikethrough:
            Text("S")
                .font(.system(size: 28, weight: .regular))
                .strikethrough()
                .frame(width: 24, height: 24)
        case .inlineCode:
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 24, weight: .medium))
                .frame(width: 28, height: 24)
        case .reference:
            Image(systemName: "quote.opening")
                .font(.system(size: 24, weight: .medium))
                .frame(width: 24, height: 24)
        case .colors:
            HStack(spacing: 2) {
                Text("A")
                    .font(.system(size: 28, weight: .regular))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
            }
            .frame(width: 32, height: 24)
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
                .frame(width: iconSize, height: iconSize)
        }
    }

    private var iconSize: CGFloat {
        item.toolType == .left && !item.isRealTool ? 23 : 22
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
