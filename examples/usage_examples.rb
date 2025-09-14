# frozen_string_literal: true

# JapaneseBusinessDays 使用例とベストプラクティス
#
# このファイルは、JapaneseBusinessDaysライブラリの様々な使用方法と
# ベストプラクティスを示すサンプルコードを提供します。

require "japanese_business_days"
require "date"

puts "=== JapaneseBusinessDays 使用例 ==="
puts

# =============================================================================
# 1. 基本的な営業日計算
# =============================================================================

puts "1. 基本的な営業日計算"
puts "-" * 40

# 営業日数の計算
start_date = Date.new(2024, 1, 1)
end_date = Date.new(2024, 1, 10)
business_days = JapaneseBusinessDays.business_days_between(start_date, end_date)
puts "#{start_date} から #{end_date} までの営業日数: #{business_days}日"

# 営業日判定
test_dates = [
  Date.new(2024, 1, 1),   # 元日（祝日）
  Date.new(2024, 1, 2),   # 平日
  Date.new(2024, 1, 6),   # 土曜日
  Date.new(2024, 1, 8)    # 成人の日（祝日）
]

test_dates.each do |date|
  is_business_day = JapaneseBusinessDays.business_day?(date)
  is_holiday = JapaneseBusinessDays.holiday?(date)
  day_type = if is_holiday
               "祝日"
             elsif date.saturday? || date.sunday?
               "週末"
             else
               "平日"
             end

  puts "#{date} (#{date.strftime("%A")}): #{day_type} - 営業日: #{is_business_day ? "はい" : "いいえ"}"
end

puts

# =============================================================================
# 2. 営業日の加算・減算
# =============================================================================

puts "2. 営業日の加算・減算"
puts "-" * 40

base_date = Date.new(2024, 1, 5) # 金曜日
puts "基準日: #{base_date} (#{base_date.strftime("%A")})"

# 営業日加算
[1, 3, 5, 10].each do |days|
  result = JapaneseBusinessDays.add_business_days(base_date, days)
  puts "  +#{days}営業日後: #{result} (#{result.strftime("%A")})"

  # 営業日減算
  result = JapaneseBusinessDays.subtract_business_days(base_date, days)
  puts "  -#{days}営業日前: #{result} (#{result.strftime("%A")})"
end

# 次の営業日・前の営業日
next_bday = JapaneseBusinessDays.next_business_day(base_date)
prev_bday = JapaneseBusinessDays.previous_business_day(base_date)
puts "  次の営業日: #{next_bday} (#{next_bday.strftime("%A")})"
puts "  前の営業日: #{prev_bday} (#{prev_bday.strftime("%A")})"

puts

# =============================================================================
# 3. 祝日情報の取得
# =============================================================================

puts "3. 祝日情報の取得"
puts "-" * 40

# 2024年の祝日を取得
holidays_2024 = JapaneseBusinessDays.holidays_in_year(2024)
puts "2024年の祝日一覧 (#{holidays_2024.length}日):"

holidays_2024.each do |holiday|
  puts "  #{holiday.date} - #{holiday.name} (#{holiday.type})"
end

puts

# 祝日の種類別分類
holiday_types = holidays_2024.group_by(&:type)
holiday_types.each do |type, holidays|
  type_name = case type
              when :fixed then "固定祝日"
              when :calculated then "計算祝日"
              when :happy_monday then "ハッピーマンデー祝日"
              when :substitute then "振替休日"
              end
  puts "#{type_name}: #{holidays.length}日"
end

puts

# =============================================================================
# 4. カスタム設定の使用
# =============================================================================

puts "4. カスタム設定の使用"
puts "-" * 40

# 設定前の状態
puts "設定前:"
puts "  2024/12/31は営業日か: #{JapaneseBusinessDays.business_day?(Date.new(2024, 12, 31))}"
puts "  2024/1/1は営業日か: #{JapaneseBusinessDays.business_day?(Date.new(2024, 1, 1))}"

# カスタム設定を適用
JapaneseBusinessDays.configure do |config|
  # 大晦日を祝日に追加
  config.add_holiday(Date.new(2024, 12, 31))

  # 元日を営業日として扱う（祝日を上書き）
  config.add_business_day(Date.new(2024, 1, 1))

  # 土曜日のみを週末に設定（日曜日は営業日）
  config.weekend_days = [6]
end

puts "\n設定後:"
puts "  2024/12/31は営業日か: #{JapaneseBusinessDays.business_day?(Date.new(2024, 12, 31))}"
puts "  2024/1/1は営業日か: #{JapaneseBusinessDays.business_day?(Date.new(2024, 1, 1))}"
puts "  2024/1/7（日曜日）は営業日か: #{JapaneseBusinessDays.business_day?(Date.new(2024, 1, 7))}"

# 設定をリセット
JapaneseBusinessDays.configuration.reset!
puts "\n設定リセット後:"
puts "  2024/12/31は営業日か: #{JapaneseBusinessDays.business_day?(Date.new(2024, 12, 31))}"
puts "  2024/1/1は営業日か: #{JapaneseBusinessDays.business_day?(Date.new(2024, 1, 1))}"

puts

# =============================================================================
# 5. Date拡張メソッドの使用（Rails環境をシミュレート）
# =============================================================================

puts "5. Date拡張メソッドの使用"
puts "-" * 40

# Date拡張を手動で適用（通常はRailsで自動適用される）
Date.include(JapaneseBusinessDays::DateExtensions)
Time.include(JapaneseBusinessDays::DateExtensions)

test_date = Date.new(2024, 1, 5)
puts "基準日: #{test_date}"

# 拡張メソッドの使用
puts "  営業日か: #{test_date.business_day?}"
puts "  祝日か: #{test_date.holiday?}"
puts "  +3営業日後: #{test_date.add_business_days(3)}"
puts "  -2営業日前: #{test_date.subtract_business_days(2)}"
puts "  次の営業日: #{test_date.next_business_day}"
puts "  前の営業日: #{test_date.previous_business_day}"

# Timeオブジェクトでの使用（時刻情報が保持される）
test_time = Time.new(2024, 1, 5, 14, 30, 0)
puts "\n時刻付きオブジェクト: #{test_time}"
next_business_time = test_time.add_business_days(1)
puts "  +1営業日後: #{next_business_time} (時刻情報が保持される)"

puts

# =============================================================================
# 6. 実用的なユースケース
# =============================================================================

puts "6. 実用的なユースケース"
puts "-" * 40

# ユースケース1: 支払期日の計算
invoice_date = Date.new(2024, 1, 15)
payment_due_date = JapaneseBusinessDays.add_business_days(invoice_date, 30)
puts "請求書発行日: #{invoice_date}"
puts "支払期日（30営業日後）: #{payment_due_date}"

# ユースケース2: プロジェクトのマイルストーン計算
project_start = Date.new(2024, 2, 1)
milestones = [10, 20, 30, 45].map do |days|
  JapaneseBusinessDays.add_business_days(project_start, days)
end

puts "\nプロジェクト開始日: #{project_start}"
puts "マイルストーン:"
milestones.each_with_index do |date, index|
  puts "  第#{index + 1}段階 (#{[10, 20, 30, 45][index]}営業日後): #{date}"
end

# ユースケース3: 月末営業日の計算
def last_business_day_of_month(year, month)
  # 月の最終日から逆算して最初の営業日を見つける
  last_day = Date.new(year, month, -1)
  current_date = last_day

  loop do
    return current_date if JapaneseBusinessDays.business_day?(current_date)

    current_date -= 1
  end
end

puts "\n2024年各月の月末営業日:"
(1..12).each do |month|
  last_bday = last_business_day_of_month(2024, month)
  puts "  #{month}月: #{last_bday}"
end

# ユースケース4: 営業日のみの日付範囲生成
def business_days_in_range(start_date, end_date)
  business_days = []
  current_date = start_date

  while current_date <= end_date
    business_days << current_date if JapaneseBusinessDays.business_day?(current_date)
    current_date += 1
  end

  business_days
end

range_start = Date.new(2024, 1, 1)
range_end = Date.new(2024, 1, 15)
business_days_list = business_days_in_range(range_start, range_end)

puts "\n#{range_start} から #{range_end} までの営業日:"
business_days_list.each do |date|
  puts "  #{date} (#{date.strftime("%A")})"
end

puts

# =============================================================================
# 7. パフォーマンス考慮事項
# =============================================================================

puts "7. パフォーマンス考慮事項"
puts "-" * 40

# 大量計算のパフォーマンステスト
require "benchmark"

puts "1000回の営業日計算のパフォーマンス:"
time = Benchmark.measure do
  1000.times do |i|
    base = Date.new(2024, 1, 1) + i
    JapaneseBusinessDays.add_business_days(base, 5)
  end
end

puts "  実行時間: #{time.real.round(4)}秒"
puts "  1回あたり: #{(time.real / 1000 * 1000).round(4)}ミリ秒"

# 祝日キャッシュの効果
puts "\n複数年の祝日取得（キャッシュ効果のテスト）:"
time = Benchmark.measure do
  (2020..2030).each do |year|
    JapaneseBusinessDays.holidays_in_year(year)
  end
end

puts "  11年分の祝日取得時間: #{time.real.round(4)}秒"

puts

# =============================================================================
# 8. エラーハンドリングの例
# =============================================================================

puts "8. エラーハンドリングの例"
puts "-" * 40

# 無効な引数のテスト
test_cases = [
  { desc: "nil日付", code: -> { JapaneseBusinessDays.business_day?(nil) } },
  { desc: "無効な日付文字列", code: -> { JapaneseBusinessDays.business_day?("invalid-date") } },
  { desc: "無効な年", code: -> { JapaneseBusinessDays.holidays_in_year(99_999) } },
  { desc: "無効な営業日数", code: -> { JapaneseBusinessDays.add_business_days(Date.today, "invalid") } }
]

test_cases.each do |test_case|
  test_case[:code].call
  puts "  #{test_case[:desc]}: エラーが発生しませんでした（予期しない結果）"
rescue JapaneseBusinessDays::Error => e
  puts "  #{test_case[:desc]}: #{e.class.name} - #{e.message.split("|").first.strip}"
end

puts
puts "=== 使用例の実行完了 ==="
