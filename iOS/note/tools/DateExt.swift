//
//  DateExt.swift
//  note
//
//  Created by 倪申雷 on 2025/6/21.
//

import Foundation

extension Calendar {

    static var gregorian: Calendar = Calendar(identifier: .gregorian)
    
}

extension Date {
    
    var calendar: Calendar {
        Calendar.gregorian
    }
    
    /// 获取一天的开始时间
    var startOfDay: Date {
        return calendar.startOfDay(for: self)
    }
    
    /// 获取一天的结束时间
    var endOfDay: Date {
        let startOfDay = self.startOfDay
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)
        return endOfDay!
    }
    
    /// 获取当月的第一天
    var startOfMonth: Date {
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }
    
    /// 获取当月的最后一天
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.day = -1
        return calendar.date(byAdding: components, to: self.startOfMonth)!
    }
    
    /// 获取一年的第一天
    var startOfYear: Date {
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components)!
    }

    /// 获取一年的最后一天
    var endOfYear: Date {
        var components = DateComponents()
        components.year = 1
        components.second = -1
        return calendar.date(byAdding: components, to: self.startOfYear)!
    }
    
}

extension Date {
    
    static func createDate(year: Int, month: Int) -> Date? {
        let calendar = Calendar.gregorian
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1  // 默认为当月第一天
        return calendar.date(from: components)
    }
    
}

extension Date {
    
    func addMonth(_ value: Int) -> Date {
        let calendar = Calendar.gregorian
        var components = DateComponents()
        components.month = value
        // 处理月份加减时的边界问题（如 1月31日 +1个月 → 2月28/29日）
        return calendar.date(byAdding: components, to: self, wrappingComponents: true) ?? self
    }
    
    func addYear(_ value: Int) -> Date {
        let calendar = Calendar.gregorian
        var components = DateComponents()
        components.year = value
        
        // 处理闰年等边界情况（如 2020-02-29 +1年 → 2021-02-28）
        return calendar.date(byAdding: components, to: self, wrappingComponents: true) ?? self
    }
    
}
extension Date {
    
    // 计算当前月的前置空白单元格数量
    var currentMonthStartPadding: Int {
        let calendar = Calendar.gregorian
        let startOfMonth = self.startOfMonth
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        return (firstWeekday - calendar.firstWeekday + 7) % 7
    }
    
    // 生成当前月所有日期 (仅当前月)
    var currentMonthDays: [Date] {
        let startOfMonth = self.startOfMonth
        let calendar = Calendar.gregorian
        // 获取当月天数
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count else {
            return []
        }
        // 生成当月日期数组
        return (0..<daysInMonth).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: startOfMonth)
        }
    }
    
}

extension Date {

    var day: Int {
        Calendar.current.component(.day, from: self)
    }
    
    var month: Int {
        Calendar.current.component(.month, from: self)
    }
    
    var year: Int {
        Calendar.current.component(.year, from: self)
    }
}
