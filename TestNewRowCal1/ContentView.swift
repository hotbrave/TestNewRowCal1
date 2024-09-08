import SwiftUI

struct ContentView: View {
    @State private var items: [Date] = []  // 存储要显示的日期
    @State private var scrollViewProxy: ScrollViewProxy? = nil  // 用于滚动到特定位置

    let columns = Array(repeating: GridItem(.flexible()), count: 7) // 每行显示 7 列，类似日历布局

    var body: some View {
        VStack {
            // 固定显示星期几的部分
            HStack {
                ForEach(0..<7) { index in
                    Text(getWeekdaySymbol(for: index))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(index == 0 ? .red : .primary) // 周日标为红色
                }
            }
            .padding(.top)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 30) {  // 使用 LazyVStack 实现月份分隔
                        // 按月份分隔显示
                        ForEach(groupedByMonth(items), id: \.self) { monthDates in
                            if let firstDate = monthDates.first {
                                VStack(alignment: .leading) {
                                    // 显示月份标题，左对齐
                                    Text("\(getYearTitle(date: firstDate))年 \(getMonthTitle(date: firstDate))")
                                        .font(.title3)
                                        .bold()
                                        .padding(.vertical, 10)
                                        .padding(.leading)

                                    // 日期部分使用 LazyVGrid 显示
                                    LazyVGrid(columns: columns, spacing: 10) {
                                        ForEach(paddedDays(for: monthDates), id: \.self) { day in
                                            if let date = day {
                                                VStack {
                                                    // 高亮显示今天的日期
                                                    if Calendar.current.isDateInToday(date) {
                                                        Text(getDay(date: date))
                                                            .font(.headline)
                                                            .foregroundColor(.white)
                                                            .frame(width: 35, height: 35)
                                                            .background(Color.red)
                                                            .cornerRadius(5)
                                                            .id("today")  // 给当天日期设置 ID
                                                    } else {
                                                        Text(getDay(date: date))
                                                            .font(.headline)
                                                            .foregroundColor(.primary)
                                                            .frame(width: 35, height: 35)
                                                            .background(Color.clear)
                                                    }
                                                }
                                            } else {
                                                // 空白占位符，用于填补不满的一行
                                                Text("")
                                                    .frame(width: 35, height: 35)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    scrollViewProxy = proxy
                    loadInitialDates()  // 载入默认日期
                    // 等待视图加载完成后再滚动
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollToToday()  // 应用启动时滚动到今天
                    }
                }
            }

            HStack {
                Spacer()

                // 添加新一年的按钮
                Button(action: {
                    addNextYear()
                }) {
                    Text("添加新一年")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // 滚动到今天的按钮
                Button(action: {
                    scrollToToday()
                }) {
                    Text("滚动到今天")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }

    // 获取星期的符号（从星期日到星期六）
    func getWeekdaySymbol(for index: Int) -> String {
        let symbols = Calendar.current.shortWeekdaySymbols
        return symbols[index]
    }

    // 获取月份名称
    func getMonthTitle(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }

    // 获取年份
    func getYearTitle(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }

    // 获取公历的日（几号）
    func getDay(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    // 将日期按月分组
    func groupedByMonth(_ dates: [Date]) -> [[Date]] {
        var grouped = [[Date]]()
        var currentMonth = -1
        var currentGroup = [Date]()

        for date in dates {
            let month = Calendar.current.component(.month, from: date)
            if month != currentMonth {
                if !currentGroup.isEmpty {
                    grouped.append(currentGroup)
                }
                currentGroup = [Date]()
                currentMonth = month
            }
            currentGroup.append(date)
        }

        if !currentGroup.isEmpty {
            grouped.append(currentGroup)
        }

        return grouped
    }

    // 按星期排列日期，填充空白占位符
    func paddedDays(for monthDates: [Date]) -> [Date?] {
        var paddedDates = [Date?]()

        if let firstDate = monthDates.first {
            let firstWeekday = Calendar.current.component(.weekday, from: firstDate) - 1
            paddedDates.append(contentsOf: Array(repeating: nil, count: firstWeekday)) // 填充空白
        }

        paddedDates.append(contentsOf: monthDates)

        let remainder = paddedDates.count % 7
        if remainder > 0 {
            paddedDates.append(contentsOf: Array(repeating: nil, count: 7 - remainder)) // 填充到满一行
        }

        return paddedDates
    }

    // 滚动到今天的日期
    func scrollToToday() {
        // 使用 ScrollViewProxy 滚动到当天的 ID "today"
        DispatchQueue.main.async {
            scrollViewProxy?.scrollTo("today", anchor: .center)
        }
    }

    // 加载初始日期（当前年、上一年和下一年）
    func loadInitialDates() {
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)

        // 加载前一年，当前年，和下一年
        for yearOffset in -1...1 {
            addDates(forYear: currentYear + yearOffset)
        }
    }

    // 为特定年份添加所有日期
    func addDates(forYear year: Int) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // 获取该年的每一天
        if let startDate = dateFormatter.date(from: "\(year)-01-01"),
           let endDate = dateFormatter.date(from: "\(year)-12-31") {
            var date = startDate
            while date <= endDate {
                items.append(date)
                date = calendar.date(byAdding: .day, value: 1, to: date)!
            }
        }
    }

    // 添加下一年
    func addNextYear() {
        let calendar = Calendar.current
        if let lastDate = items.last {
            let nextYear = calendar.component(.year, from: lastDate) + 1
            addDates(forYear: nextYear)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
