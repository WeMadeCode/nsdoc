import SwiftUI


struct YearCalendarView: View {
    
    @StateObject var yearCalendarViewModel = YearCalendarViewModel(currentYear: Date())
    @Environment(\.modelContext) private var modelContext
    @State private var hasJump = false
    @State private var isActive = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 年份导航控制
            headerView
            // 年度日历主体
            calendarGridView
        }
        .navigationDestination(isPresented: $isActive, destination: {
            MonthCalendarView(
                targetDate: Date(),
                selectedDate: Date()
            )
        })
        .onAppear(perform: {
            yearCalendarViewModel.fetchDatas(modelContext: modelContext)
            if hasJump == false {
                isActive = true
                hasJump = true
            }
        })
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 顶部导航
    private var headerView: some View {
        HStack {
            Button(action: {
                yearCalendarViewModel.addYear(value: -1)
                yearCalendarViewModel.fetchDatas(modelContext: modelContext)
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(10)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("\(yearCalendarViewModel.currentYear.year)")
                .font(.title2.bold())
                .onTapGesture {
                    yearCalendarViewModel.currentYear = Date()
                    yearCalendarViewModel.fetchDatas(modelContext: modelContext)
                }
            
            Spacer()
            
            Button(action: {
                yearCalendarViewModel.addYear(value: 1)
                yearCalendarViewModel.fetchDatas(modelContext: modelContext)
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(10)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
        }
        .padding(.bottom, 10)
    }
    
    private var calendarGridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 0) {
                ForEach(yearCalendarViewModel.months, id: \.self) { monthInfo in
                    YearMonthItemView(monthInfo: monthInfo)
                }
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
    
}


#Preview {
    YearCalendarView()
}

