import SwiftUI

struct MonthCalendarView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject var viewModel: MonthCalendarViewModel
    
    init(targetDate: Date, selectedDate: Date) {
        self._viewModel = StateObject(
            wrappedValue: MonthCalendarViewModel(
                currentDate: targetDate,
                selectedDate: selectedDate
            )
        )
    }
    
    private let calendar = Calendar.gregorian
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private let weekdaySymbols: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            weekdaysView
            calendarGridView
            eventsListView
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.fetchDatas(modelContext: modelContext)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("\(viewModel.currentDate.year) 年")
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .font(.title2)
                    .foregroundStyle(.black)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white.opacity(0.7))
                           
                    )
                }
            }
        }
    }
    
    // MARK: - 顶部导航
    private var headerView: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(10)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text(dateFormatter.string(from: viewModel.currentDate))
                .font(.title2.bold())
                .onTapGesture {
                    withAnimation {
                        viewModel.currentDate = Date()
                        viewModel.selectedDate = Date()
                        viewModel.fetchDatas(modelContext: modelContext)
                    }
                }
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(10)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
        }
        .padding(.bottom, 10)
    }
    
    // MARK: - 星期标题
    private var weekdaysView: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 4)
    }
    
    // MARK: - 日历网格 (仅显示当前月日期)
    private var calendarGridView: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 0) {
            // 前置填充 - 空白单元格
            ForEach(viewModel.paddingItems, id: \.self) { _ in
                Color.clear
                    .frame(height: 44)
                    .allowsHitTesting(false) // 禁用交互
            }
            
            // 当前月日期
            ForEach(viewModel.monthItems, id: \.self) { item in
                DayView(
                    date: item.date,
                    isToday: calendar.isDateInToday(item.date),
                    isSelected: calendar.isDate(item.date, inSameDayAs: viewModel.selectedDate),
                    eventsCount: item.articleCount
                )
                .frame(height: 44)
                .onTapGesture {
                    withAnimation(.spring()) {
                        viewModel.selectedDate = item.date
                        viewModel.updateSelectedDateArticles(modelContext: modelContext)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }
    
    // MARK: - 事件列表
    private var eventsListView: some View {
        ScrollView {
            Text(eventListTitle)
                .font(.headline.bold())
                .padding(.top, 20)
                .padding(.bottom, 8)
            
            if !viewModel.selectedDateArticles.isEmpty {
                VStack(spacing: 12) {
                    ForEach(viewModel.selectedDateArticles, id: \.self) { article in
                        NavigationLink {
                            EditorView(article: article)
                                .toolbar(.hidden, for: .tabBar)
                        } label: {
                            eventRow(article: article)
                        }
                    }
                }
            } else {
                Text("无安排")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            }
        }
        .padding(.top, 20)
    }
    
    private var eventListTitle: String {
        if calendar.isDateInToday(viewModel.selectedDate) {
            return "今日事件"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return formatter.string(from: viewModel.selectedDate) + "事件"
        }
    }
    
    private func eventRow(article: Article) -> some View {
        HStack(alignment: .top) {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            Text(article.title)
                .font(.subheadline)
                .padding(.leading, 8)
            
            Spacer()
        }
        .padding(10)
        .background(Color(.tertiarySystemFill))
        .cornerRadius(10)
    }
    
    // 上个月
    private func previousMonth() {
        withAnimation(.easeInOut) {
            viewModel.currentDate = calendar.date(byAdding: .month, value: -1, to: viewModel.currentDate)!
            viewModel.selectedDate = viewModel.currentDate.startOfMonth
            viewModel.fetchDatas(modelContext: modelContext)
        }
    }
    
    // 下个月
    private func nextMonth() {
        withAnimation(.easeInOut) {
            viewModel.currentDate = calendar.date(byAdding: .month, value: 1, to: viewModel.currentDate)!
            viewModel.selectedDate = viewModel.currentDate.startOfMonth
            viewModel.fetchDatas(modelContext: modelContext)
        }
    }
    
}

// MARK: - 日历日期视图 (仅当前月)
struct DayView: View {
    
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let eventsCount: Int
    
    private let calendar = Calendar.gregorian
    
    var body: some View {
        ZStack {
            // 选中状态背景
            if isSelected {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 36, height: 36)
            }
            
            // 今天标记
            if isToday && !isSelected {
                Circle()
                    .stroke(Color.red, lineWidth: 1)
                    .frame(width: 36, height: 36)
            }
            
            // 日期文本
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(
                    isSelected ? .white :
                    (calendar.isDateInWeekend(date) ? .secondary : .primary)
                )
            
            // 事件标记
            if eventsCount > 0 {
                VStack(spacing: 2) {
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(0..<min(eventsCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(isSelected ? Color.white : Color.blue)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}



// MARK: - 预览
#Preview {
    //MonthCalendarView(targetDate: Date(), selectedDate: Date())
}
