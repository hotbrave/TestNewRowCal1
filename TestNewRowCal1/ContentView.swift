import SwiftUI

// 扩展 Calendar，用于处理中国农历
extension Calendar {
    static let chinese = Calendar(identifier: .chinese)
}

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
                                        ForEach(paddedDays(for: monthDates), id: \.1.uuidString) { (day, _) in
                                            if let date = day {
                                                VStack {
                                                    // 高亮显示今天的日期
                                                    if Calendar.current.isDateInToday(date) {
                                                        VStack {
                                                            Text(getDay(date: date))
                                                                .font(.headline)
                                                                .foregroundColor(.white)
                                                                .frame(width: 35, height: 35)
                                                                .background(Color.red)
                                                                .cornerRadius(5)
                                                                .id("today")  // 给当天日期设置 ID
                                                            let _ = print("today is ready")

                                                            // 显示农历日期
                                                            Text(getChineseLunarDay(for: date, showMonth: isFirstDayOfChineseMonth(date)))
                                                                .font(.caption)
                                                                .foregroundColor(.gray)
                                                        }
                                                    } else {
                                                        VStack {
                                                            Text(getDay(date: date))
                                                                .font(.headline)
                                                                .foregroundColor(.primary)
                                                                .frame(width: 35, height: 35)
                                                                .background(Color.clear)

                                                            // 显示农历日期（仅日期或月份和日期）
                                                            Text(getChineseLunarDay(for: date, showMonth: isFirstDayOfChineseMonth(date)))
                                                                .font(.caption)
                                                                .foregroundColor(.gray)
                                                        }
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
                                .id(getMonthID(for: firstDate))  // 给月份设置 ID
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    scrollViewProxy = proxy
                    loadInitialDates()  // 载入默认日期

                    let today = Date()
                    let targetMonthID = getMonthID(for: today)  // 获取今天所在月份的 ID

                    // 等待视图加载完成后再滚动
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        // 滚动到今天所在的月份
                        proxy.scrollTo(targetMonthID, anchor: .top)
                        
                        // 确保滚动到今天
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.scrollTo("today", anchor: .center)
                        }
                    }
                }
            }

            HStack {
                Spacer()

                // 滚动到今天的按钮
                Button(action: {
                    let today = Date()
                    let targetMonthID = getMonthID(for: today)  // 获取今天所在月份的 ID

                    // 先滚动到今天所在的月份
                    scrollViewProxy?.scrollTo(targetMonthID, anchor: .top)

                    // 确保滚动到今天
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollViewProxy?.scrollTo("today", anchor: .center)
                    }
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
        let chineseWeekdays = ["日", "一", "二", "三", "四", "五", "六"]
        return "周" + chineseWeekdays[index]
    }

    // 获取月份名称
    func getMonthTitle(date: Date) -> String {
        let chineseMonths = ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
        let month = Calendar.current.component(.month, from: date)
        return chineseMonths[month - 1]
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

    // 按星期排列日期，填充空白占位符，并为每个日期生成唯一ID
    func paddedDays(for monthDates: [Date]) -> [(Date?, UUID)] {
        var paddedDates = [(Date?, UUID)]()

        if let firstDate = monthDates.first {
            let firstWeekday = Calendar.current.component(.weekday, from: firstDate) - 1
            paddedDates.append(contentsOf: Array(repeating: (nil, UUID()), count: firstWeekday)) // 填充空白
        }

        paddedDates.append(contentsOf: monthDates.map { ($0, UUID()) })

        let remainder = paddedDates.count % 7
        if remainder > 0 {
            paddedDates.append(contentsOf: Array(repeating: (nil, UUID()), count: 7 - remainder)) // 填充到满一行
        }

        return paddedDates
    }

    // 滚动到今天的日期
    func scrollToToday() {
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
        for yearOffset in -100...100 {
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

    // 获取农历日期
    func getChineseLunarDay(for date: Date, showMonth: Bool) -> String {
        let chineseCalendar = Calendar.chinese
        let day = chineseCalendar.component(.day, from: date)
        let month = chineseCalendar.component(.month, from: date)
        let chineseMonths = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"]
        let chineseDays = ["初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十", "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十", "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]

        let chineseMonth = chineseMonths[month - 1]
        let chineseDay = day <= chineseDays.count ? chineseDays[day - 1] : ""

        return showMonth ? chineseMonth : chineseDay
    }

    // 判断是否为农历月份的第一天
    func isFirstDayOfChineseMonth(_ date: Date) -> Bool {
        let chineseCalendar = Calendar.chinese
        let day = chineseCalendar.component(.day, from: date)
        return day == 1
    }

    // 根据日期生成唯一的月份ID
    func getMonthID(for date: Date) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        return "\(year)\(String(format: "%02d", month))"  // 返回类似 "202409" 这样的 ID
    }
}
