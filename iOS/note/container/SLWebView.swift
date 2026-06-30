//
//  SLWebView.swift
//  note
//
//  Created by 倪申雷 on 2025/7/9.
//

import SwiftUI
import WebKit
#if os(iOS)
import UIKit
import ObjectiveC.runtime
#elseif os(macOS)
import AppKit
#endif

protocol SLWebViewCoordinatorParent {
    var url: URL { get }
    var platformLogName: String { get }
    var isLoadFinsh: (() -> Void)? { get }
    var bridgeReady: (() -> Void)? { get }
    var contentChanged: ((EditorContentSnapshot) -> Void)? { get }
    var toolsUpdate: (([ToolType: Bool], EditorSelectionContext) -> Void)? { get }
    var pickImageAttachment: (([String: Any]?, @escaping NSBridgeHandlerCompletion) -> Void)? { get }
    var resolveImageAttachment: (([String: Any]?) -> Result<Any?, NSBridgeRuntimeError>)? { get }

    func webViewDidFinishLoading(_ webView: WKWebView, bridge: NSBridgeNative)
}

private enum SLWebViewScripts {
    static let lightMode = WKUserScript(
        source: """
        document.documentElement.classList.remove('dark');
        document.documentElement.style.colorScheme = 'light';

        const colorSchemeMeta = document.querySelector('meta[name="color-scheme"]') || document.createElement('meta');
        colorSchemeMeta.name = 'color-scheme';
        colorSchemeMeta.content = 'light';

        if (!colorSchemeMeta.parentNode) {
            document.head.appendChild(colorSchemeMeta);
        }
        """,
        injectionTime: .atDocumentStart,
        forMainFrameOnly: true
    )

    static func runtimeConfig(hostPlatform: String, editorMode: String) -> WKUserScript {
        WKUserScript(
            source: """
            window.__NSRuntimeConfig = Object.freeze({
                hostPlatform: '\(hostPlatform)',
                editorMode: '\(editorMode)'
            });
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
    }
}

private func makeEditorWebViewConfiguration(
    bridge: NSBridgeNative,
    hostPlatform: String,
    editorMode: String
) -> WKWebViewConfiguration {
    let configuration = NSBridgeWebViewInstaller.makeConfiguration(bridge: bridge)
    configuration.userContentController.addUserScript(SLWebViewScripts.lightMode)
    configuration.userContentController.addUserScript(
        SLWebViewScripts.runtimeConfig(hostPlatform: hostPlatform, editorMode: editorMode)
    )
    return configuration
}

final class SLWebViewCoordinator: NSObject, WKNavigationDelegate {
    var parent: any SLWebViewCoordinatorParent
    let bridge = NSBridgeNative()
    private var lastExecutedCommandID: UUID?

    init(parent: any SLWebViewCoordinatorParent) {
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
            onError: { _ in }
        )

        MediaBridgeHandlers.register(
            on: bridge,
            pickImage: { [weak self] params, completion in
                guard let self, let pickImageAttachment = self.parent.pickImageAttachment else {
                    completion(.failure(NSBridgeRuntimeError(code: .methodNotFound, message: "media.pickImage is not available")))
                    return
                }

                pickImageAttachment(params, completion)
            },
            resolveImage: { [weak self] params in
                guard let self, let resolveImageAttachment = self.parent.resolveImageAttachment else {
                    return .failure(NSBridgeRuntimeError(code: .methodNotFound, message: "media.resolveImage is not available"))
                }

                return resolveImageAttachment(params)
            }
        )
    }

    func execute(_ command: JavaScriptCommand) -> Bool {
        guard lastExecutedCommandID != command.id else {
            return false
        }

        lastExecutedCommandID = command.id
        bridge.callWeb(
            namespace: command.namespace,
            method: command.methodName,
            params: command.params,
            timeout: command.timeout
        ) { result in
            command.completion?(result)
        }
        return true
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        bridge.resetForNavigation()
        log("开始加载", webView: webView)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        log("已收到页面内容", webView: webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        log("加载成功", webView: webView)
        parent.webViewDidFinishLoading(webView, bridge: bridge)
        parent.isLoadFinsh?()
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        logFailure("建立连接失败", error: error, webView: webView)
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        logFailure("页面加载失败", error: error, webView: webView)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        log("WebContent 进程已终止", webView: webView)
    }

    private func log(_ message: String, webView: WKWebView) {
        let url = webView.url?.absoluteString ?? parent.url.absoluteString
        print("[EditorWebView][\(parent.platformLogName)] \(message) | URL: \(url)")
    }

    private func logFailure(_ message: String, error: Error, webView: WKWebView) {
        let nsError = error as NSError
        let url = webView.url?.absoluteString ?? parent.url.absoluteString
        print(
            "[EditorWebView][\(parent.platformLogName)] \(message) | URL: \(url) | " +
            "Error: \(nsError.domain)(\(nsError.code)) \(nsError.localizedDescription)"
        )
    }
}

#if os(iOS)

struct SLWebView: UIViewRepresentable, SLWebViewCoordinatorParent {
    
    let url: URL
    @Binding var javaScriptCommand: JavaScriptCommand?
    @ObservedObject var viewModel: EditorViewModel
    let customKeyboardHeight: CGFloat
    let isLoadFinsh: (() -> Void)?
    let bridgeReady: (() -> Void)?
    let contentChanged: ((EditorContentSnapshot) -> Void)?
    let toolsUpdate: (([ToolType: Bool], EditorSelectionContext) -> Void)?
    let pickImageAttachment: (([String: Any]?, @escaping NSBridgeHandlerCompletion) -> Void)?
    let resolveImageAttachment: (([String: Any]?) -> Result<Any?, NSBridgeRuntimeError>)?
    
    init(url: URL,
         javaScriptCommand: Binding<JavaScriptCommand?>,
         viewModel: EditorViewModel,
         customKeyboardHeight: CGFloat,
         isLoadFinsh: (() -> Void)? = nil,
         bridgeReady: (() -> Void)? = nil,
         contentChanged: ((EditorContentSnapshot) -> Void)? = nil,
         toolsUpdate: (([ToolType: Bool], EditorSelectionContext) -> Void)? = nil,
         pickImageAttachment: (([String: Any]?, @escaping NSBridgeHandlerCompletion) -> Void)? = nil,
         resolveImageAttachment: (([String: Any]?) -> Result<Any?, NSBridgeRuntimeError>)? = nil
    ) {
        self.url = url
        self._javaScriptCommand = javaScriptCommand
        self.viewModel = viewModel
        self.customKeyboardHeight = customKeyboardHeight
        self.isLoadFinsh = isLoadFinsh
        self.bridgeReady = bridgeReady
        self.contentChanged = contentChanged
        self.toolsUpdate = toolsUpdate
        self.pickImageAttachment = pickImageAttachment
        self.resolveImageAttachment = resolveImageAttachment
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = makeEditorWebViewConfiguration(
            bridge: context.coordinator.bridge,
            hostPlatform: "iphone",
            editorMode: "simple"
        )

        let wkWebView = WKWebView(frame: .zero, configuration: configuration)
        context.coordinator.bridge.attach(webView: wkWebView)
        wkWebView.hideKeyboardAccessoryBar()
        wkWebView.setCustomKeyboard(
            isEnabled: viewModel.isCustomKeyboardVisible,
            bridge: context.coordinator.bridge,
            height: customKeyboardHeight,
            activeTools: viewModel.activeTools,
            onToolExecuted: {
                viewModel.closeCustomKeyboard()
                wkWebView.switchToSystemKeyboard(
                    bridge: context.coordinator.bridge,
                    height: customKeyboardHeight,
                    activeTools: viewModel.activeTools
                )
            },
            animated: false
        )
        wkWebView.navigationDelegate = context.coordinator
        wkWebView.overrideUserInterfaceStyle = .light
        wkWebView.isOpaque = false
        wkWebView.backgroundColor = .clear
        #if DEBUG
        wkWebView.isInspectable = true
        #endif
        wkWebView.scrollView.isScrollEnabled = false
        wkWebView.scrollView.bounces = false
        wkWebView.scrollView.showsVerticalScrollIndicator = false
        wkWebView.scrollView.showsHorizontalScrollIndicator = false
        if url.isFileURL {
            wkWebView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            let request = URLRequest(url: url)
            wkWebView.load(request)
        }
        return wkWebView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.parent = self
        uiView.setCustomKeyboard(
            isEnabled: viewModel.isCustomKeyboardVisible,
            bridge: context.coordinator.bridge,
            height: customKeyboardHeight,
            activeTools: viewModel.activeTools,
            onToolExecuted: {
                viewModel.closeCustomKeyboard()
                uiView.switchToSystemKeyboard(
                    bridge: context.coordinator.bridge,
                    height: customKeyboardHeight,
                    activeTools: viewModel.activeTools
                )
            },
            animated: true
        )

        if let javaScriptCommand {
            guard context.coordinator.execute(javaScriptCommand) else {
                return
            }

            DispatchQueue.main.async {
                if self.javaScriptCommand?.id == javaScriptCommand.id {
                    self.javaScriptCommand = nil
                }
            }
        }
    }
    
    func makeCoordinator() -> SLWebViewCoordinator {
        SLWebViewCoordinator(parent: self)
    }

    var platformLogName: String {
        "iOS"
    }

    func webViewDidFinishLoading(_ webView: WKWebView, bridge: NSBridgeNative) {
        webView.hideKeyboardAccessoryBar()
        webView.setCustomKeyboard(
            isEnabled: viewModel.isCustomKeyboardVisible,
            bridge: bridge,
            height: customKeyboardHeight,
            activeTools: viewModel.activeTools,
            onToolExecuted: {
                viewModel.closeCustomKeyboard()
            },
            animated: false
        )
    }
    
}

private extension WKWebView {
    func switchToSystemKeyboard(
        bridge: NSBridgeNative,
        height: CGFloat,
        activeTools: [ToolType: Bool]
    ) {
        setCustomKeyboard(
            isEnabled: false,
            bridge: bridge,
            height: height,
            activeTools: activeTools,
            onToolExecuted: {},
            animated: true
        )

        bridge.callWeb(namespace: "editor", method: "focus", timeout: 2) { _ in }
    }

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

    func setCustomKeyboard(
        isEnabled: Bool,
        bridge: NSBridgeNative,
        height: CGFloat,
        activeTools: [ToolType: Bool],
        onToolExecuted: @escaping () -> Void,
        animated: Bool
    ) {
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
                (subview.customEditorInputView as? EditorInsertKeyboardView)?.updateActiveTools(activeTools)
                return
            }

            subview.currentInputViewMode = newMode
            subview.currentCustomInputViewHeight = normalizedHeight
            subview.setCustomInputView(
                isEnabled
                    ? EditorInsertKeyboardView(
                        bridge: bridge,
                        height: normalizedHeight,
                        animated: animated,
                        onToolExecuted: onToolExecuted
                    )
                    : nil
            )
            (subview.customEditorInputView as? EditorInsertKeyboardView)?.updateActiveTools(activeTools)

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

            (subview.customEditorInputView as? EditorInsertKeyboardView)?.updateActiveTools(activeTools)
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

    var customEditorInputView: UIView? {
        objc_getAssociatedObject(self, &AssociatedInputViewKey.customInputView) as? UIView
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
        let toolType: ToolType?
        let title: String
        let iconTitle: String?
        let systemImage: String?
        let iconColor: UIColor
    }

    private struct Section {
        let title: String
        let blocks: [Block]
    }

    private let bridge: NSBridgeNative
    private let shouldAnimateIn: Bool
    private let onToolExecuted: () -> Void
    private var buttonsByToolType: [ToolType: UIButton] = [:]
    private var blocksByToolType: [ToolType: Block] = [:]
    private let mutuallyExclusiveBlockTools: Set<ToolType> = [
        .text, .h1, .h2, .h3, .h4, .h5, .order, .unOrder, .check, .reference, .code
    ]
    private let sections: [Section] = [
        Section(title: "基础部分", blocks: [
            Block(toolType: .text, title: "文本", iconTitle: "T", systemImage: nil, iconColor: .tertiaryLabel),
            Block(toolType: .h1, title: "标题 H1", iconTitle: "H1", systemImage: nil, iconColor: .tertiaryLabel),
            Block(toolType: .h2, title: "标题 H2", iconTitle: "H2", systemImage: nil, iconColor: .tertiaryLabel),
            Block(toolType: .h3, title: "标题 H3", iconTitle: "H3", systemImage: nil, iconColor: .tertiaryLabel),
            Block(toolType: .h4, title: "标题 H4", iconTitle: "H4", systemImage: nil, iconColor: .tertiaryLabel),
            Block(toolType: .h5, title: "标题 H5", iconTitle: "H5", systemImage: nil, iconColor: .tertiaryLabel),
            Block(toolType: .order, title: "有序列表", iconTitle: nil, systemImage: "list.number", iconColor: .tertiaryLabel),
            Block(toolType: .unOrder, title: "无序列表", iconTitle: nil, systemImage: "list.bullet", iconColor: .tertiaryLabel),
            Block(toolType: .check, title: "任务列表", iconTitle: nil, systemImage: "checklist", iconColor: .tertiaryLabel),
            Block(toolType: .reference, title: "引用块", iconTitle: nil, systemImage: "quote.opening", iconColor: .tertiaryLabel)
        ]),
        Section(title: "高级部分", blocks: [
            Block(toolType: .picture, title: "图片", iconTitle: nil, systemImage: "photo.on.rectangle.angled", iconColor: .systemPink),
            Block(toolType: .table, title: "表格", iconTitle: nil, systemImage: "tablecells", iconColor: .systemTeal),
            Block(toolType: .code, title: "代码块", iconTitle: nil, systemImage: "chevron.left.forwardslash.chevron.right", iconColor: .systemIndigo)
        ])
    ]

    init(bridge: NSBridgeNative, height: CGFloat, animated: Bool, onToolExecuted: @escaping () -> Void) {
        self.bridge = bridge
        self.shouldAnimateIn = animated
        self.onToolExecuted = onToolExecuted
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
        grid.spacing = 14

        let columnCount = 5
        for rowStart in stride(from: 0, to: blocks.count, by: columnCount) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .fillEqually
            grid.addArrangedSubview(row)

            for offset in 0..<columnCount {
                let index = rowStart + offset
                row.addArrangedSubview(index < blocks.count ? makeButton(for: blocks[index]) : UIView())
            }
        }

        return grid
    }

    private func makeButton(for block: Block) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        configuration.imagePlacement = .top
        configuration.imagePadding = 6
        configuration.titleAlignment = .center

        let button = UIButton(configuration: configuration)
        button.heightAnchor.constraint(equalToConstant: 82).isActive = true
        button.backgroundColor = .clear
        button.contentHorizontalAlignment = .center
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.78

        if let toolType = block.toolType, !toolType.jsMethodName.isEmpty {
            button.addAction(UIAction { [weak self] _ in
                self?.runTool(toolType)
            }, for: .touchUpInside)
            buttonsByToolType[toolType] = button
            blocksByToolType[toolType] = block
        }

        applyStyle(to: button, for: block, isActive: false)
        return button
    }

    func updateActiveTools(_ activeTools: [ToolType: Bool]) {
        buttonsByToolType.forEach { toolType, button in
            guard let block = blocksByToolType[toolType] else {
                return
            }

            applyStyle(to: button, for: block, isActive: activeTools[toolType] ?? false)
        }
    }

    private func runTool(_ toolType: ToolType) {
        guard !toolType.jsMethodName.isEmpty else {
            return
        }

        onToolExecuted()

        bridge.callWeb(
            namespace: "editor",
            method: toolType.jsMethodName,
            params: toolType.jsParams,
            timeout: 2
        ) { [weak self] result in
            guard case .success(let data) = result else {
                return
            }

            DispatchQueue.main.async {
                self?.applyCommandResult(data, for: toolType)
            }
        }
    }

    private func applyCommandResult(_ data: Any?, for toolType: ToolType) {
        guard
            let result = data as? [String: Any],
            let isActive = result["active"] as? Bool
        else {
            return
        }

        if isActive, mutuallyExclusiveBlockTools.contains(toolType) {
            mutuallyExclusiveBlockTools.forEach { updateButton(for: $0, isActive: false) }
        }

        updateButton(for: toolType, isActive: isActive)
    }

    private func updateButton(for toolType: ToolType, isActive: Bool) {
        guard
            let button = buttonsByToolType[toolType],
            let block = blocksByToolType[toolType]
        else {
            return
        }

        applyStyle(to: button, for: block, isActive: isActive)
    }

    private func applyStyle(to button: UIButton, for block: Block, isActive: Bool) {
        button.isSelected = false
        button.tintColor = isActive ? .systemBlue : iconForegroundColor(for: block)
        button.configuration?.baseForegroundColor = isActive ? .systemBlue : .secondaryLabel
        button.configuration?.background.backgroundColor = .clear

        button.setImage(makeBlockIconImage(for: block, isActive: isActive), for: .normal)

        if isActive {
            button.accessibilityTraits.insert(.selected)
        } else {
            button.accessibilityTraits.remove(.selected)
        }

        button.setAttributedTitle(NSAttributedString(
            string: block.title,
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: isActive ? UIColor.systemBlue : UIColor.secondaryLabel
            ]
        ), for: .normal)
        button.titleLabel?.textAlignment = .center
    }

    private func makeBlockIconImage(for block: Block, isActive: Bool) -> UIImage? {
        let size = CGSize(width: 52, height: 52)
        let foregroundColor = isActive ? UIColor.systemBlue : iconForegroundColor(for: block)
        let backgroundColor = isActive ? UIColor.systemBlue.withAlphaComponent(0.12) : iconBackgroundColor(for: block)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 10)
            backgroundColor.setFill()
            path.fill()

            if isActive {
                UIColor.systemBlue.withAlphaComponent(0.18).setStroke()
                path.lineWidth = 1
                path.stroke()
            }

            if let systemImage = block.systemImage {
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
                guard let image = UIImage(systemName: systemImage, withConfiguration: symbolConfig) else {
                    return
                }

                let iconSize = image.size
                let drawRect = CGRect(
                    x: (size.width - iconSize.width) / 2,
                    y: (size.height - iconSize.height) / 2,
                    width: iconSize.width,
                    height: iconSize.height
                )
                foregroundColor.setFill()
                image.withTintColor(foregroundColor, renderingMode: .alwaysTemplate).draw(in: drawRect)
                context.cgContext.setFillColor(foregroundColor.cgColor)
            } else if let iconTitle = block.iconTitle {
                drawIconTitle(iconTitle, in: rect, color: foregroundColor)
            }
        }.withRenderingMode(.alwaysOriginal)
    }

    private func drawIconTitle(_ text: String, in rect: CGRect, color: UIColor) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: text.count > 1 ? 23 : 27, weight: .regular),
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: 0,
            y: (rect.height - textSize.height) / 2,
            width: rect.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attributes)
    }

    private func iconForegroundColor(for block: Block) -> UIColor {
        switch block.toolType {
        case .text, .h1, .h2, .h3, .h4, .h5, .order, .unOrder, .check, .reference, .strikethrough:
            return .label
        default:
            return block.iconColor
        }
    }

    private func iconBackgroundColor(for block: Block) -> UIColor {
        switch block.toolType {
        case .text, .h1, .h2, .h3, .h4, .h5, .order, .unOrder, .check, .reference, .strikethrough:
            return UIColor.secondarySystemBackground.withAlphaComponent(0.78)
        default:
            return block.iconColor.withAlphaComponent(0.12)
        }
    }
}


#Preview {
}
#elseif os(macOS)
struct SLWebView: NSViewRepresentable, SLWebViewCoordinatorParent {
    let url: URL
    @Binding var javaScriptCommand: JavaScriptCommand?
    @ObservedObject var viewModel: EditorViewModel
    let customKeyboardHeight: CGFloat
    let isLoadFinsh: (() -> Void)?
    let bridgeReady: (() -> Void)?
    let contentChanged: ((EditorContentSnapshot) -> Void)?
    let toolsUpdate: (([ToolType: Bool], EditorSelectionContext) -> Void)?
    let pickImageAttachment: (([String: Any]?, @escaping NSBridgeHandlerCompletion) -> Void)?
    let resolveImageAttachment: (([String: Any]?) -> Result<Any?, NSBridgeRuntimeError>)?

    init(
        url: URL,
        javaScriptCommand: Binding<JavaScriptCommand?>,
        viewModel: EditorViewModel,
        customKeyboardHeight: CGFloat,
        isLoadFinsh: (() -> Void)? = nil,
        bridgeReady: (() -> Void)? = nil,
        contentChanged: ((EditorContentSnapshot) -> Void)? = nil,
        toolsUpdate: (([ToolType: Bool], EditorSelectionContext) -> Void)? = nil,
        pickImageAttachment: (([String: Any]?, @escaping NSBridgeHandlerCompletion) -> Void)? = nil,
        resolveImageAttachment: (([String: Any]?) -> Result<Any?, NSBridgeRuntimeError>)? = nil
    ) {
        self.url = url
        self._javaScriptCommand = javaScriptCommand
        self.viewModel = viewModel
        self.customKeyboardHeight = customKeyboardHeight
        self.isLoadFinsh = isLoadFinsh
        self.bridgeReady = bridgeReady
        self.contentChanged = contentChanged
        self.toolsUpdate = toolsUpdate
        self.pickImageAttachment = pickImageAttachment
        self.resolveImageAttachment = resolveImageAttachment
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = makeEditorWebViewConfiguration(
            bridge: context.coordinator.bridge,
            hostPlatform: "mac",
            editorMode: "notion"
        )

        let webView = WKWebView(frame: .zero, configuration: configuration)
        context.coordinator.bridge.attach(webView: webView)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        #if DEBUG
        webView.isInspectable = true
        #endif
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self

        if let javaScriptCommand {
            guard context.coordinator.execute(javaScriptCommand) else {
                return
            }

            DispatchQueue.main.async {
                if self.javaScriptCommand?.id == javaScriptCommand.id {
                    self.javaScriptCommand = nil
                }
            }
        }
    }

    func makeCoordinator() -> SLWebViewCoordinator {
        SLWebViewCoordinator(parent: self)
    }

    var platformLogName: String {
        "macOS"
    }

    func webViewDidFinishLoading(_ webView: WKWebView, bridge: NSBridgeNative) {
    }
}
#endif
