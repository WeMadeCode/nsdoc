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

    var body: some View {
        VStack(spacing: 8) {
            if viewModel.mainTools[0].isSelected {
                ScrollView(.horizontal, showsIndicators: false) {
                    subTools(with: $viewModel.subFontTools)
                        .padding(.horizontal, 18)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if viewModel.mainTools[1].isSelected {
                ScrollView(.horizontal, showsIndicators: false) {
                    subTools(with: $viewModel.subAlignTools)
                        .padding(.horizontal, 18)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            mainTools(with: $viewModel.mainTools)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.clear)
        .animation(.spring(response: 0.25, dampingFraction: 0.88), value: viewModel.mainTools[0].isSelected)
        .animation(.spring(response: 0.25, dampingFraction: 0.88), value: viewModel.mainTools[1].isSelected)
    }
    
    func mainTools(with items: Binding<[ToolItem]>) -> some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items) { item in
                        ToolBarButton(item: item) {
                            let itemValue = item.wrappedValue
                            if itemValue.isRealTool == false {
                                item.wrappedValue.isSelected.toggle()
                            } else {
                                guard !itemValue.toolType.jsMethodName.isEmpty else {
                                    return
                                }
                                javaScriptCommand = JavaScriptCommand(
                                    methodName: itemValue.toolType.jsMethodName,
                                    params: itemValue.toolType.jsParams,
                                    completion: nil)
                            }
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
        .frame(minHeight: 56)
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
    
    func subTools(with items: Binding<[ToolItem]>) -> some View {
        HStack(spacing: 10) {
            ForEach(items) { item in
                ToolBarButton(item: item) {
                    let itemValue = item.wrappedValue
                    guard !itemValue.toolType.jsMethodName.isEmpty else {
                        return
                    }
                    javaScriptCommand = JavaScriptCommand(
                        methodName: itemValue.toolType.jsMethodName,
                        params: itemValue.toolType.jsParams,
                        completion: nil
                    )
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
    
}

private struct ToolBarButton: View {
    @Binding var item: ToolItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if item.toolType == .text && !item.isRealTool {
                    Text("格式")
                        .font(.system(size: 17, weight: .semibold))
                        .fixedSize()
                } else {
                    item.image
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                }

                if !item.isRealTool {
                    Image(systemName: item.isSelected ? "chevron.down" : "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                        .opacity(0.72)
                }
            }
            .frame(minWidth: item.toolType == .text && !item.isRealTool ? 68 : 42, minHeight: 38)
            .foregroundStyle(item.isSelected ? Color(.systemBlue) : Color(.label).opacity(0.82))
            .padding(.horizontal, item.toolType == .text && !item.isRealTool ? 2 : 0)
            .background(
                Capsule()
                    .fill(item.isSelected ? Color(.systemBlue).opacity(0.12) : Color.clear)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
//    Tools(javaScriptCommand: <#Binding<JavaScriptCommand?>#>, viewModel: EditorViewModel())
}
