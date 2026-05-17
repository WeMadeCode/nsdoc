//
//  CloudKitAccountService.swift
//  note
//
//  Created by Codex on 2026/5/17.
//

import CloudKit
import Foundation

enum CloudKitAccountState: Equatable {
    case checking
    case available
    case noAccount
    case restricted
    case couldNotDetermine
    case error(String)
}

extension CloudKitAccountState {
    var allowsSync: Bool {
        switch self {
        case .available:
            return true
        default:
            return false
        }
    }

    var title: String {
        switch self {
        case .checking:
            return "正在检查 CloudKit"
        case .available:
            return "CloudKit 可用"
        case .noAccount:
            return "未登录 Apple ID"
        case .restricted:
            return "CloudKit 受限"
        case .couldNotDetermine:
            return "无法确认 CloudKit 状态"
        case .error:
            return "CloudKit 检查失败"
        }
    }

    var message: String {
        switch self {
        case .checking:
            return "正在确认当前设备的同步状态。"
        case .available:
            return "笔记将保存到本地，并通过 CloudKit 同步。"
        case .noAccount:
            return "你仍可在本机记录笔记；登录系统 Apple ID 后会恢复 CloudKit 同步。"
        case .restricted:
            return "当前设备限制了 CloudKit 访问，你仍可继续使用本地笔记。"
        case .couldNotDetermine:
            return "暂时无法确认 CloudKit 状态，你仍可继续使用本地笔记。"
        case .error(let reason):
            return reason.isEmpty ? "暂时无法检查 CloudKit 状态。" : reason
        }
    }
}

@MainActor
final class CloudKitAccountService: ObservableObject {
    @Published private(set) var state: CloudKitAccountState = .checking
    @Published private(set) var lastCheckedAt: Date?

    private let container: CKContainer

    init(container: CKContainer = CKContainer(identifier: CloudKitConfig.containerIdentifier)) {
        self.container = container
    }

    func refresh() {
        state = .checking

        container.accountStatus { [weak self] status, error in
            Task { @MainActor in
                guard let self else { return }
                self.lastCheckedAt = Date()

                if let error {
                    self.state = .error(error.localizedDescription)
                    return
                }

                switch status {
                case .available:
                    self.state = .available
                case .noAccount:
                    self.state = .noAccount
                case .restricted:
                    self.state = .restricted
                case .couldNotDetermine:
                    self.state = .couldNotDetermine
                case .temporarilyUnavailable:
                    self.state = .error("CloudKit 暂时不可用，稍后会再次检查。")
                @unknown default:
                    self.state = .couldNotDetermine
                }
            }
        }
    }
}
