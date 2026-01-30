//
//  YearMonthItemView.swift
//  note
//
//  Created by 倪申雷 on 2025/7/27.
//
import SwiftUI

struct YearMonthItemView: View {
    
    let monthInfo: MonthInfo
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let cellHeight: CGFloat = 30
    
    var body: some View {
        VStack(spacing: 2) {
            // 月份标题
            Text(monthInfo.title)
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            
            // 星期标题
            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, weekday in
                    Text(weekday)
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
            
            // 日期网格
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(monthInfo.days, id: \.self) { dayInfo in
                    if let day = dayInfo.day {
                        NavigationLink(destination:
                            MonthCalendarView(
                                targetDate: day,
                                selectedDate: day
                            )
                        ) {
                            DayCell(dayInfo: dayInfo)
                        }
                    } else {
                        // 空白占位符
                        Text("")
                            .frame(maxWidth: .infinity, minHeight: cellHeight)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .frame(minHeight: 260) // 固定月份视图高度
    }
    
    private let weekdays = Calendar.gregorian.veryShortWeekdaySymbols
    
    // 日期单元格视图
    struct DayCell: View {
        let dayInfo: DayInfo
        
        var body: some View {
            ZStack {
                Rectangle()
                    .fill(dayInfo.isHaveData ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: 22, height: 22)
                    .clipShape(.buttonBorder)
                    .opacity(dayInfo.isNotMock ? 1.0 : 0.0)
                Text("\(dayInfo.day?.day ?? 0)")
                    .font(.system(size: 12, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .foregroundColor(.white)
                    .opacity(dayInfo.isNotMock ? 1.0 : 0.0)
            }
        }
    }
    
 }
