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
        VStack(spacing: 4) {
            if viewModel.mainTools[0].isSelected {
                ScrollView(.horizontal, showsIndicators: false) {
                    subTools(with: $viewModel.subFontTools)
                        .padding(.horizontal, 4)
                }
                .padding(.bottom, 2)
            }
            if viewModel.mainTools[1].isSelected {
                HStack {
                    subTools(with: $viewModel.subAlignTools)
                        .padding(.leading, 50)
                    Spacer()
                }
                .padding(.bottom, 2)
            }
            mainTools(with: $viewModel.mainTools)
        }
    }
    
    func mainTools(with items: Binding<[ToolItem]>) -> some View {
        
        HStack(spacing: 15) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(items) { item in
                        HighlightableButton(
                            image: item.image,
                            isSelected: item.isSelected
                        ) {
                            let itemValue = item.wrappedValue
                            if itemValue.isRealTool == false {
                                item.wrappedValue.isSelected.toggle()
                            } else {
                                javaScriptCommand = JavaScriptCommand(
                                    methodName: itemValue.toolType.jsMethodName,
                                    arguments: itemValue.toolType.jsArguments,
                                    completion: nil)
                            }
                        }
                    }
                }
            }
        
            Spacer()
            
            HighlightableButton(
                image: .constant(Image(systemName: "keyboard.chevron.compact.down")),
                isSelected: .constant(false),
                action: {
                UIApplication.shared.endEditing()
            })
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
    }
    
    func subTools(with items: Binding<[ToolItem]>) -> some View {
        HStack(spacing: 15) {
            ForEach(items) { item in
                HighlightableButton(image: item.image, isSelected: item.isSelected) {
                    let itemValue = item.wrappedValue
                    javaScriptCommand = JavaScriptCommand(
                        methodName: itemValue.toolType.jsMethodName,
                        arguments: itemValue.toolType.jsArguments,
                        completion: nil
                    )
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1) // 描边
                )
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 5,
                    x: 0,
                    y: 2  // 阴影效果
                )
        )
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
