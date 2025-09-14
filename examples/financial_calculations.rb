# frozen_string_literal: true

# 金融業界での営業日計算サンプル
#
# このファイルは、銀行、証券会社、保険会社などの金融機関で
# よく使用される営業日計算のパターンを示します。

require 'japanese_business_days'
require 'date'

puts "=== 金融業界での営業日計算サンプル ==="
puts

# =============================================================================
# 1. 決済日計算（T+N決済）
# =============================================================================

puts "1. 決済日計算（T+N決済）"
puts "-" * 40

# 株式取引の決済日計算（T+2決済）
def calculate_settlement_date(trade_date, settlement_days = 2)
  JapaneseBusinessDays.add_business_days(trade_date, settlement_days)
end

trade_date = Date.new(2024, 1, 5)  # 金曜日に取引
settlement_date = calculate_settlement_date(trade_date, 2)

puts "取引日: #{trade_date} (#{trade_date.strftime('%A')})"
puts "決済日 (T+2): #{settlement_date} (#{settlement_date.strftime('%A')})"

# 外国為替の決済日計算（T+1決済）
fx_settlement = calculate_settlement_date(trade_date, 1)
puts "外為決済日 (T+1): #{fx_settlement} (#{fx_settlement.strftime('%A')})"

puts

# =============================================================================
# 2. 金利計算期間の営業日数
# =============================================================================

puts "2. 金利計算期間の営業日数"
puts "-" * 40

def calculate_interest_days(start_date, end_date, day_count_convention = :business_days)
  case day_count_convention
  when :business_days
    JapaneseBusinessDays.business_days_between(start_date, end_date)
  when :calendar_days
    (end_date - start_date).to_i
  when :actual_365
    (end_date - start_date).to_i
  end
end

loan_start = Date.new(2024, 1, 1)
loan_end = Date.new(2024, 3, 31)

business_days = calculate_interest_days(loan_start, loan_end, :business_days)
calendar_days = calculate_interest_days(loan_start, loan_end, :calendar_days)

puts "融資期間: #{loan_start} ～ #{loan_end}"
puts "営業日数: #{business_days}日"
puts "暦日数: #{calendar_days}日"

# 金利計算例（年利2.5%、営業日ベース）
principal = 10_000_000  # 元本1000万円
annual_rate = 0.025     # 年利2.5%
interest = principal * annual_rate * business_days / 250  # 年間営業日数を250日と仮定

puts "元本: #{principal.to_s.reverse.gsub(/(\d{3})/, '\1,').reverse.sub(/^,/, '')}円"
puts "年利: #{(annual_rate * 100)}%"
puts "利息 (営業日ベース): #{interest.round.to_s.reverse.gsub(/(\d{3})/, '\1,').reverse.sub(/^,/, '')}円"

puts

# =============================================================================
# 3. 債券の利払日計算
# =============================================================================

puts "3. 債券の利払日計算"
puts "-" * 40

class BondCouponCalculator
  def initialize(issue_date, maturity_date, coupon_frequency = 2)
    @issue_date = issue_date
    @maturity_date = maturity_date
    @coupon_frequency = coupon_frequency  # 年2回（半年毎）
  end
  
  def coupon_dates
    dates = []
    months_interval = 12 / @coupon_frequency
    current_date = @issue_date
    
    while current_date < @maturity_date
      current_date = add_months(current_date, months_interval)
      break if current_date > @maturity_date
      
      # 利払日が非営業日の場合は翌営業日に調整
      adjusted_date = adjust_to_business_day(current_date)
      dates << adjusted_date
    end
    
    dates
  end
  
  private
  
  def add_months(date, months)
    new_month = date.month + months
    new_year = date.year + (new_month - 1) / 12
    new_month = ((new_month - 1) % 12) + 1
    
    # 月末日の調整
    last_day_of_month = Date.new(new_year, new_month, -1).day
    new_day = [date.day, last_day_of_month].min
    
    Date.new(new_year, new_month, new_day)
  end
  
  def adjust_to_business_day(date)
    return date if JapaneseBusinessDays.business_day?(date)
    
    # Following Business Day Convention（翌営業日）
    JapaneseBusinessDays.next_business_day(date)
  end
end

# 5年債の利払日計算例
bond_issue = Date.new(2024, 1, 15)
bond_maturity = Date.new(2029, 1, 15)
calculator = BondCouponCalculator.new(bond_issue, bond_maturity, 2)

puts "債券発行日: #{bond_issue}"
puts "満期日: #{bond_maturity}"
puts "利払日一覧:"

calculator.coupon_dates.each_with_index do |date, index|
  puts "  第#{index + 1}回: #{date} (#{date.strftime('%A')})"
end

puts

# =============================================================================
# 4. オプション満期日の計算
# =============================================================================

puts "4. オプション満期日の計算"
puts "-" * 40

class OptionExpiryCalculator
  # 日経225オプションの満期日計算（SQ日）
  # 毎月第2金曜日の前営業日
  def self.monthly_sq_date(year, month)
    # 第2金曜日を求める
    first_day = Date.new(year, month, 1)
    first_friday = first_day + ((5 - first_day.wday) % 7)
    second_friday = first_friday + 7
    
    # 第2金曜日の前営業日
    JapaneseBusinessDays.previous_business_day(second_friday)
  end
  
  # 週次オプションの満期日（毎週金曜日、祝日の場合は前営業日）
  def self.weekly_expiry_date(target_friday)
    return target_friday if JapaneseBusinessDays.business_day?(target_friday)
    
    JapaneseBusinessDays.previous_business_day(target_friday)
  end
end

# 2024年の月次SQ日計算
puts "2024年 日経225オプション月次SQ日:"
(1..12).each do |month|
  sq_date = OptionExpiryCalculator.monthly_sq_date(2024, month)
  puts "  #{month}月: #{sq_date} (#{sq_date.strftime('%A')})"
end

# 週次オプション満期日の例
puts "\n週次オプション満期日の例（2024年1月）:"
current_date = Date.new(2024, 1, 1)
end_date = Date.new(2024, 1, 31)

while current_date <= end_date
  if current_date.friday?
    expiry = OptionExpiryCalculator.weekly_expiry_date(current_date)
    puts "  #{current_date} → 満期日: #{expiry}"
  end
  current_date += 1
end

puts

# =============================================================================
# 5. 資金繰り計画
# =============================================================================

puts "5. 資金繰り計画"
puts "-" * 40

class CashFlowPlanner
  def initialize(base_date = Date.today)
    @base_date = base_date
    @cash_flows = []
  end
  
  def add_inflow(amount, business_days_from_base, description)
    date = JapaneseBusinessDays.add_business_days(@base_date, business_days_from_base)
    @cash_flows << {
      date: date,
      amount: amount,
      type: :inflow,
      description: description
    }
  end
  
  def add_outflow(amount, business_days_from_base, description)
    date = JapaneseBusinessDays.add_business_days(@base_date, business_days_from_base)
    @cash_flows << {
      date: date,
      amount: -amount,
      type: :outflow,
      description: description
    }
  end
  
  def generate_report
    sorted_flows = @cash_flows.sort_by { |flow| flow[:date] }
    running_balance = 0
    
    puts "基準日: #{@base_date}"
    puts "資金繰り予定:"
    puts "日付       | 入金        | 出金        | 残高        | 摘要"
    puts "-" * 70
    
    sorted_flows.each do |flow|
      running_balance += flow[:amount]
      
      inflow = flow[:type] == :inflow ? format_currency(flow[:amount]) : ""
      outflow = flow[:type] == :outflow ? format_currency(-flow[:amount]) : ""
      
      puts "#{flow[:date]} | #{inflow.ljust(11)} | #{outflow.ljust(11)} | #{format_currency(running_balance).ljust(11)} | #{flow[:description]}"
    end
  end
  
  private
  
  def format_currency(amount)
    amount.to_s.reverse.gsub(/(\d{3})/, '\1,').reverse.sub(/^,/, '')
  end
end

# 資金繰り計画の例
planner = CashFlowPlanner.new(Date.new(2024, 1, 15))

# 入金予定
planner.add_inflow(50_000_000, 3, "売掛金回収")
planner.add_inflow(30_000_000, 7, "融資実行")
planner.add_inflow(20_000_000, 15, "債券償還")

# 出金予定
planner.add_outflow(25_000_000, 5, "買掛金支払")
planner.add_outflow(15_000_000, 10, "給与支払")
planner.add_outflow(40_000_000, 12, "設備投資")

planner.generate_report

puts

# =============================================================================
# 6. 金融機関の営業日設定例
# =============================================================================

puts "6. 金融機関の営業日設定例"
puts "-" * 40

# 銀行の営業日設定（大晦日は休業）
puts "銀行の営業日設定:"
JapaneseBusinessDays.configure do |config|
  config.add_holiday(Date.new(2024, 12, 31))  # 大晦日を休業日に
end

test_dates = [
  Date.new(2024, 12, 29),  # 金曜日
  Date.new(2024, 12, 30),  # 土曜日
  Date.new(2024, 12, 31),  # 日曜日（大晦日）
  Date.new(2025, 1, 1),    # 月曜日（元日）
  Date.new(2025, 1, 2),    # 火曜日
]

test_dates.each do |date|
  is_business_day = JapaneseBusinessDays.business_day?(date)
  puts "  #{date} (#{date.strftime('%A')}): #{is_business_day ? '営業日' : '休業日'}"
end

# 設定をリセット
JapaneseBusinessDays.configuration.reset!

puts
puts "=== 金融業界サンプル完了 ==="