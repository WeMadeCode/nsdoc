//
//  SLWebView.swift
//  note
//
//  Created by 倪申雷 on 2025/7/9.
//

import SwiftUI
import WebKit
import ObjectiveC.runtime

struct JavaScriptCommand {
    let id: UUID = UUID()
    let namespace: String
    let methodName: String
    let params: [String: Any]?
    let timeout: TimeInterval
    var completion: ((Result<Any?, NSBridgeRuntimeError>) -> Void)?

    init(
        namespace: String = "editor",
        methodName: String,
        params: [String: Any]? = nil,
        timeout: TimeInterval = 2,
        completion: ((Result<Any?, NSBridgeRuntimeError>) -> Void)? = nil
    ) {
        self.namespace = namespace
        self.methodName = methodName
        self.params = params
        self.timeout = timeout
        self.completion = completion
    }
}

struct SLWebView: UIViewRepresentable {
    
    let url: URL
    @Binding var javaScriptCommand: JavaScriptCommand?
    @ObservedObject var viewModel: EditorViewModel
    let customKeyboardHeight: CGFloat
    let isLoadFinsh: (() -> Void)?
    let bridgeReady: (() -> Void)?
    let contentChanged: ((EditorContentSnapshot) -> Void)?
    let toolsUpdate: (([ToolType: Bool], EditorSelectionContext) -> Void)?
    
    init(url: URL,
         javaScriptCommand: Binding<JavaScriptCommand?>,
         viewModel: EditorViewModel,
         customKeyboardHeight: CGFloat,
         isLoadFinsh: (() -> Void)? = nil,
         bridgeReady: (() -> Void)? = nil,
         contentChanged: ((EditorContentSnapshot) -> Void)? = nil,
         toolsUpdate: (([ToolType: Bool], EditorSelectionContext) -> Void)? = nil
    ) {
        self.url = url
        self._javaScriptCommand = javaScriptCommand
        self.viewModel = viewModel
        self.customKeyboardHeight = customKeyboardHeight
        self.isLoadFinsh = isLoadFinsh
        self.bridgeReady = bridgeReady
        self.contentChanged = contentChanged
        self.toolsUpdate = toolsUpdate
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = NSBridgeWebViewInstaller.makeConfiguration(bridge: context.coordinator.bridge)
        let wkWebView = WKWebView(frame: .zero, configuration: configuration)
        context.coordinator.bridge.attach(webView: wkWebView)
        wkWebView.hideKeyboardAccessoryBar()
        wkWebView.setCustomKeyboard(
            isEnabled: viewModel.isCustomKeyboardVisible,
            bridge: context.coordinator.bridge,
            height: customKeyboardHeight,
            animated: false
        )
        wkWebView.navigationDelegate = context.coordinator
        wkWebView.isOpaque = false
        wkWebView.backgroundColor = .clear
        wkWebView.isInspectable = true
        wkWebView.scrollView.isScrollEnabled = false
        wkWebView.scrollView.bounces = false
        let request = URLRequest(url: url)
        wkWebView.load(request)
        return wkWebView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.parent = self
        uiView.setCustomKeyboard(
            isEnabled: viewModel.isCustomKeyboardVisible,
            bridge: context.coordinator.bridge,
            height: customKeyboardHeight,
            animated: true
        )

        if let javaScriptCommand {
            guard context.coordinator.lastExecutedCommandID != javaScriptCommand.id else {
                return
            }
            context.coordinator.lastExecutedCommandID = javaScriptCommand.id

            context.coordinator.bridge.callWeb(
                namespace: javaScriptCommand.namespace,
                method: javaScriptCommand.methodName,
                params: javaScriptCommand.params,
                timeout: javaScriptCommand.timeout
            ) { result in
                javaScriptCommand.completion?(result)
            }

            DispatchQueue.main.async {
                if self.javaScriptCommand?.id == javaScriptCommand.id {
                    self.javaScriptCommand = nil
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        
        var parent: SLWebView
        let bridge = NSBridgeNative()
        var lastExecutedCommandID: UUID?
        
        init(_ parent: SLWebView) {
            self.parent = parent
            super.init()
            EditorBridgeHandlers.register(
                on: bridge,
                onReady: { [weak self] in
                    self?.parent.bridgeReady?()
                },
                onContentChanged: { [weak self] snapshot in
                    self?.parent.contentChanged?(snapshot)
                },
                onSelectionChanged: { [weak self] activeTools, selectionContext in
                    self?.parent.toolsUpdate?(activeTools, selectionContext)
                },
                onError: { _ in
                }
            )
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            bridge.resetForNavigation()
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.hideKeyboardAccessoryBar()
            webView.setCustomKeyboard(
                isEnabled: parent.viewModel.isCustomKeyboardVisible,
                bridge: bridge,
                height: parent.customKeyboardHeight,
                animated: false
            )
            parent.isLoadFinsh?()
        }
    
    }
    
}

private extension WKWebView {
    func hideKeyboardAccessoryBar() {
        inputAssistantItem.leadingBarButtonGroups = []
        inputAssistantItem.trailingBarButtonGroups = []

        scrollView.subviews.forEach { subview in
            subview.inputAssistantItem.leadingBarButtonGroups = []
            subview.inputAssistantItem.trailingBarButtonGroups = []

            guard String(describing: type(of: subview)).hasPrefix("WKContent") else {
                return
            }

            subview.removeInputAccessoryView()
        }
    }

    func setCustomKeyboard(isEnabled: Bool, bridge: NSBridgeNative, height: CGFloat, animated: Bool) {
        inputAssistantItem.leadingBarButtonGroups = []
        inputAssistantItem.trailingBarButtonGroups = []

        scrollView.subviews.forEach { subview in
            guard String(describing: type(of: subview)).hasPrefix("WKContent") else {
                return
            }

            let newMode = isEnabled ? "custom" : "system"
            let oldMode = subview.currentInputViewMode
            let oldHeight = subview.currentCustomInputViewHeight
            let normalizedHeight = max(300, height)
            let didChange = oldMode != newMode || abs(oldHeight - normalizedHeight) > 0.5

            guard didChange else {
                return
            }

            subview.currentInputViewMode = newMode
            subview.currentCustomInputViewHeight = normalizedHeight
            subview.setCustomInputView(isEnabled ? EditorInsertKeyboardView(bridge: bridge, height: normalizedHeight, animated: animated) : nil)

            let reload = {
                subview.reloadInputViews()
                subview.superview?.layoutIfNeeded()
            }

            if animated {
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0,
                    options: [.curveEaseInOut, .beginFromCurrentState],
                    animations: reload
                )
            } else {
                reload()
            }
        }
    }
}

private extension UIView {
    func removeInputAccessoryView() {
        let originalClass: AnyClass = type(of: self)
        let className = String(cString: class_getName(originalClass))
        let subclassName = "\(className)_NoInputAccessoryView"

        if let subclass = NSClassFromString(subclassName) {
            object_setClass(self, subclass)
            return
        }

        guard
            let subclass = objc_allocateClassPair(originalClass, subclassName, 0),
            let method = class_getInstanceMethod(NoInputAccessoryViewProvider.self, #selector(getter: NoInputAccessoryViewProvider.inputAccessoryView))
        else {
            return
        }

        class_addMethod(
            subclass,
            #selector(getter: UIResponder.inputAccessoryView),
            method_getImplementation(method),
            method_getTypeEncoding(method)
        )

        if let inputViewMethod = class_getInstanceMethod(NoInputAccessoryViewProvider.self, #selector(getter: NoInputAccessoryViewProvider.inputView)) {
            class_addMethod(
                subclass,
                #selector(getter: UIResponder.inputView),
                method_getImplementation(inputViewMethod),
                method_getTypeEncoding(inputViewMethod)
            )
        }
        objc_registerClassPair(subclass)
        object_setClass(self, subclass)
    }

    func setCustomInputView(_ inputView: UIView?) {
        removeInputAccessoryView()
        objc_setAssociatedObject(
            self,
            &AssociatedInputViewKey.customInputView,
            inputView,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    var currentInputViewMode: String? {
        get {
            objc_getAssociatedObject(self, &AssociatedInputViewKey.currentMode) as? String
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedInputViewKey.currentMode,
                newValue,
                .OBJC_ASSOCIATION_COPY_NONATOMIC
            )
        }
    }

    var currentCustomInputViewHeight: CGFloat {
        get {
            (objc_getAssociatedObject(self, &AssociatedInputViewKey.currentHeight) as? NSNumber)?.doubleValue ?? 0
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedInputViewKey.currentHeight,
                NSNumber(value: Double(newValue)),
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

private final class NoInputAccessoryViewProvider: UIResponder {
    override var inputAccessoryView: UIView? {
        nil
    }

    override var inputView: UIView? {
        objc_getAssociatedObject(self, &AssociatedInputViewKey.customInputView) as? UIView
    }
}

private enum AssociatedInputViewKey {
    static var customInputView: UInt8 = 0
    static var currentMode: UInt8 = 0
    static var currentHeight: UInt8 = 0
}

private final class EditorInsertKeyboardView: UIView {
    private let keyboardCornerRadius: CGFloat = 28

    private struct Block {
        let title: String
        let iconTitle: String?
        let systemImage: String?
        let iconColor: UIColor
    }

    private struct Section {
        let title: String
        let blocks: [Block]
    }

    private let shouldAnimateIn: Bool
    private let sections: [Section] = [
        Section(title: "基础部分", blocks: [
            Block(title: "标题 H1", iconTitle: "H1", systemImage: nil, iconColor: .tertiaryLabel),
            Block(title: "标题 H2", iconTitle: "H2", systemImage: nil, iconColor: .tertiaryLabel),
            Block(title: "标题 H3", iconTitle: "H3", systemImage: nil, iconColor: .tertiaryLabel),
            Block(title: "标题 H4", iconTitle: "H4", systemImage: nil, iconColor: .tertiaryLabel),
            Block(title: "标题 H5", iconTitle: "H5", systemImage: nil, iconColor: .tertiaryLabel),
            Block(title: "有序列表", iconTitle: nil, systemImage: "list.number", iconColor: .tertiaryLabel),
            Block(title: "无序列表", iconTitle: nil, systemImage: "list.bullet", iconColor: .tertiaryLabel),
            Block(title: "任务列表", iconTitle: nil, systemImage: "checklist", iconColor: .tertiaryLabel),
            Block(title: "引用块", iconTitle: nil, systemImage: "quote.opening", iconColor: .tertiaryLabel),
            Block(title: "删除线", iconTitle: nil, systemImage: "strikethrough", iconColor: .tertiaryLabel)
        ]),
        Section(title: "高级部分", blocks: [
            Block(title: "图片", iconTitle: nil, systemImage: "photo.on.rectangle.angled", iconColor: .systemPink),
            Block(title: "表格", iconTitle: nil, systemImage: "tablecells", iconColor: .systemTeal),
            Block(title: "代码块", iconTitle: nil, systemImage: "chevron.left.forwardslash.chevron.right", iconColor: .systemIndigo)
        ])
    ]

    init(bridge _: NSBridgeNative, height: CGFloat, animated: Bool) {
        self.shouldAnimateIn = animated
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: max(300, height)))
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.98)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        clipsToBounds = true
        layer.cornerRadius = keyboardCornerRadius
        layer.cornerCurve = .continuous
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        let contentStack = UIStackView()
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 22
        contentView.addSubview(contentStack)

        sections.forEach { section in
            contentStack.addArrangedSubview(makeSection(section))
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -28)
        ])

        if shouldAnimateIn {
            alpha = 0
            transform = CGAffineTransform(translationX: 0, y: 18)
            UIView.animate(
                withDuration: 0.22,
                delay: 0.03,
                options: [.curveEaseOut, .beginFromCurrentState]
            ) {
                self.alpha = 1
                self.transform = .identity
            }
        }
    }

    private func makeSection(_ section: Section) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12

        let titleLabel = UILabel()
        titleLabel.text = section.title
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(makeGrid(for: section.blocks))

        return stack
    }

    private func makeGrid(for blocks: [Block]) -> UIStackView {
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 12

        for pairStart in stride(from: 0, to: blocks.count, by: 2) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 12
            row.distribution = .fillEqually
            grid.addArrangedSubview(row)

            for offset in 0..<2 {
                let index = pairStart + offset
                row.addArrangedSubview(index < blocks.count ? makeButton(for: blocks[index]) : UIView())
            }
        }

        return grid
    }

    private func makeButton(for block: Block) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 12)
        configuration.imagePadding = 12

        let button = UIButton(configuration: configuration)
        button.heightAnchor.constraint(equalToConstant: 58).isActive = true
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.separator.withAlphaComponent(0.18).cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.05
        button.layer.shadowRadius = 6
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.contentHorizontalAlignment = .leading

        let icon: UIImage?
        if let systemImage = block.systemImage {
            icon = UIImage(systemName: systemImage)
        } else {
            icon = nil
        }

        if let icon {
            button.setImage(icon, for: .normal)
            button.tintColor = block.iconColor
        }

        let attributedTitle = NSMutableAttributedString()
        if let iconTitle = block.iconTitle {
            attributedTitle.append(NSAttributedString(
                string: "\(iconTitle)   ",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
                    .foregroundColor: block.iconColor
                ]
            ))
        }
        attributedTitle.append(NSAttributedString(
            string: block.title,
            attributes: [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
        ))
        button.setAttributedTitle(attributedTitle, for: .normal)

        return button
    }
}


#Preview {
}
