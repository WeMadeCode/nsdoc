//
//  FontBridge.swift
//  note
//
//  Created by 倪申雷 on 2025/7/12.
//

import Foundation
import WebKit
import Combine

@objc
class JSBridge: NSObject {
    
    private var toolsUpdate: (([ToolType: Bool]) -> Void)?
    
    private var toolTypesActiveState: [ToolType: Bool] = [:]
    private let refreshSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    func setup(toolsUpdate: (([ToolType: Bool]) -> Void)?) {
        self.toolsUpdate = toolsUpdate
        refreshSubject
            // 防抖处理：300ms内多次触发只响应最后一次
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                toolsUpdate?(toolTypesActiveState)
            }
            .store(in: &cancellables)
    }
    
    // heading
    // level = 1、2、3、4、5、6
    // {"active":false}
    // {"active":true, "level":1}
    @objc func headingActive(_ arg: Any) -> String {
        print("headingActive: \(arg)")
        guard let dic = arg as? [String: Any],
              let active = dic["active"] as? Bool else {
            return ""
        }
        let level = dic["level"] as? Int
        if let level {
            switch level {
            case 1:
                toolTypesActiveState[.h1] = active
                toolTypesActiveState[.h2] = false
                toolTypesActiveState[.h3] = false
                toolTypesActiveState[.h4] = false
                toolTypesActiveState[.h5] = false
            case 2:
                toolTypesActiveState[.h1] = false
                toolTypesActiveState[.h2] = active
                toolTypesActiveState[.h3] = false
                toolTypesActiveState[.h4] = false
                toolTypesActiveState[.h5] = false
            case 3:
                toolTypesActiveState[.h1] = false
                toolTypesActiveState[.h2] = false
                toolTypesActiveState[.h3] = active
                toolTypesActiveState[.h4] = false
                toolTypesActiveState[.h5] = false
            case 4:
                toolTypesActiveState[.h1] = false
                toolTypesActiveState[.h2] = false
                toolTypesActiveState[.h3] = false
                toolTypesActiveState[.h4] = active
                toolTypesActiveState[.h5] = false
            case 5:
                toolTypesActiveState[.h1] = false
                toolTypesActiveState[.h2] = false
                toolTypesActiveState[.h3] = false
                toolTypesActiveState[.h4] = false
                toolTypesActiveState[.h5] = active
            default:
                break
            }
        } else {
            toolTypesActiveState[.h1] = false
            toolTypesActiveState[.h2] = false
            toolTypesActiveState[.h3] = false
            toolTypesActiveState[.h4] = false
            toolTypesActiveState[.h5] = false
        }
        refreshSubject.send()
        return ""
    }
    
    // 段落 {"active":false} {"active":true}
    @objc func paragraphActive(_ arg: Any) -> String {
        print("paragraphActive: \(arg)")
        guard let dic = arg as? [String: Any],
              let active = dic["active"] as? Bool else {
            return ""
        }
        toolTypesActiveState[.text] = active
        refreshSubject.send()
        return ""
    }
    
    // 有序列表
    @objc func orderedActive(_ arg: Any) -> String {
        print("orderedActive: \(arg)")
        guard let dic = arg as? [String: Any],
              let active = dic["active"] as? Bool else {
            return ""
        }
        toolTypesActiveState[.order] = active
        refreshSubject.send()
        return ""
    }
    
    // 无序列表
    @objc func bulletActive(_ arg: Any) -> String {
        print("bulletActive: \(arg)")
        guard let dic = arg as? [String: Any],
              let active = dic["active"] as? Bool else {
            return ""
        }
        toolTypesActiveState[.unOrder] = active
        refreshSubject.send()
        return ""
    }
    
    // 任务列表
    @objc func taskActive(_ arg: Any) -> String {
        print("taskActive: \(arg)")
        guard let dic = arg as? [String: Any],
              let active = dic["active"] as? Bool else {
            return ""
        }
        toolTypesActiveState[.check] = active
        refreshSubject.send()
        return ""
    }
    
    // 代码块
    @objc func codeBlockActive(_ arg: Any) -> String {
        print("codeBlockActive: \(arg)")
        guard let dic = arg as? [String: Any],
              let active = dic["active"] as? Bool else {
            return ""
        }
        toolTypesActiveState[.code] = active
        refreshSubject.send()
        return ""
    }
    
    // 设置引用
    @objc func blockQuoteActive(_ arg: Any) -> String {
        print("blockQuoteActive: \(arg)")
        guard let dic = arg as? [String: Any],
              let active = dic["active"] as? Bool else {
            return ""
        }
        toolTypesActiveState[.reference] = active
        refreshSubject.send()
        return ""
    }
    
    // 粗体是否激活
    @objc func boldActive(_ arg: Any) -> String {
        guard let dic = arg as? [String: Any],
              let active = dic["active"] as? Bool else {
            return ""
        }
        toolTypesActiveState[.bold] = active
        refreshSubject.send()
        return ""
    }
    
    // 斜体是否激活
    @objc func italicActive(_ arg: Any) -> String {
        guard let dic = arg as? [String: Any],
              let active = dic["active"] as? Bool else {
            return ""
        }
        toolTypesActiveState[.italic] = active
        refreshSubject.send()
        return ""
    }
    
    // 下划线是否激活
    @objc func underlineActive(_ arg: Any) -> String {
        guard let dic = arg as? [String: Any],
              let active = dic["active"] as? Bool else {
            return ""
        }
        toolTypesActiveState[.strikethrough] = active
        refreshSubject.send()
        return ""
    }
    
    // 横线是否激活
    @objc func horizontalRuleActive(_ arg: Any) -> String {
        guard let dic = arg as? [String: Any],
              let active = dic["active"] as? Bool else {
            return ""
        }
        toolTypesActiveState[.line] = active
        refreshSubject.send()
        return ""
    }
    
    // 对齐方式激活
    @objc func textAlignActive(_ arg: Any) -> String {
        print("textAlignActive: \(arg)")
        guard let dic = arg as? [String: Any],
              let active = dic["active"] as? Bool else {
            return ""
        }
//        toolTypesActiveState[.line] = active
//        refreshSubject.send()
        return ""
    }

}
