# frozen_string_literal: true

# 製造業での生産スケジュール管理サンプル
#
# このファイルは、製造業での生産計画、納期管理、
# 設備メンテナンススケジュールなどの営業日計算例を示します。

require 'japanese_business_days'
require 'date'

puts "=== 製造業での生産スケジュール管理サンプル ==="
puts

# 製造業向けの営業日設定
JapaneseBusinessDays.configure do |config|
  # 夏季休暇（お盆休み）を追加
  (Date.new(2024, 8, 13)..Date.new(2024, 8, 16)).each do |date|
    config.add_holiday(date)
  end
  
  # 年末年始の特別休暇を延長
  config.add_holiday(Date.new(2024, 12, 30))
  config.add_holiday(Date.new(2024, 12, 31))
  config.add_holiday(Date.new(2025, 1, 2))
  config.add_holiday(Date.new(2025, 1, 3))
  
  # 一部の祝日は稼働日として扱う
  config.add_business_day(Date.new(2024, 5, 3))  # 憲法記念日
  config.add_business_day(Date.new(2024, 5, 4))  # みどりの日
  config.add_business_day(Date.new(2024, 11, 3)) # 文化の日
end

# =============================================================================
# 1. 生産計画と納期管理
# =============================================================================

puts "1. 生産計画と納期管理"
puts "-" * 40

class ProductionScheduler
  def initialize
    @production_calendar = []
  end
  
  def calculate_delivery_date(order_date, production_days)
    # 受注日から生産開始日を計算（翌営業日から開始）
    production_start = JapaneseBusinessDays.next_business_day(order_date)
    
    # 生産完了日を計算
    production_end = JapaneseBusinessDays.add_business_days(production_start, production_days - 1)
    
    # 出荷日（生産完了の翌営業日）
    shipping_date = JapaneseBusinessDays.next_business_day(production_end)
    
    # 納期（出荷から2営業日後）
    delivery_date = JapaneseBusinessDays.add_business_days(shipping_date, 2)
    
    {
      order_date: order_date,
      production_start: production_start,
      production_end: production_end,
      shipping_date: shipping_date,
      delivery_date: delivery_date,
      total_lead_time: JapaneseBusinessDays.business_days_between(order_date, delivery_date)
    }
  end
  
  def batch_schedule(orders)
    orders.map do |order|
      schedule = calculate_delivery_date(order[:order_date], order[:production_days])
      schedule.merge(
        product_name: order[:product_name],
        quantity: order[:quantity]
      )
    end
  end
end

# 受注データの例
orders = [
  { product_name: "製品A", quantity: 100, order_date: Date.new(2024, 1, 15), production_days: 5 },
  { product_name: "製品B", quantity: 200, order_date: Date.new(2024, 1, 16), production_days: 8 },
  { product_name: "製品C", quantity: 50,  order_date: Date.new(2024, 1, 17), production_days: 3 },
]

scheduler = ProductionScheduler.new
schedules = scheduler.batch_schedule(orders)

puts "生産スケジュール一覧:"
puts "製品名 | 数量 | 受注日     | 生産開始   | 生産完了   | 出荷日     | 納期       | リードタイム"
puts "-" * 95

schedules.each do |schedule|
  puts "#{schedule[:product_name].ljust(6)} | #{schedule[:quantity].to_s.ljust(4)} | #{schedule[:order_date]} | #{schedule[:production_start]} | #{schedule[:production_end]} | #{schedule[:shipping_date]} | #{schedule[:delivery_date]} | #{schedule[:total_lead_time]}日"
end

puts

# =============================================================================
# 2. 設備メンテナンススケジュール
# =============================================================================

puts "2. 設備メンテナンススケジュール"
puts "-" * 40

class MaintenanceScheduler
  def initialize
    @maintenance_records = []
  end
  
  def schedule_routine_maintenance(equipment_name, last_maintenance_date, interval_days)
    next_maintenance = JapaneseBusinessDays.add_business_days(last_maintenance_date, interval_days)
    
    # メンテナンス日が祝日の場合は前営業日に調整
    if JapaneseBusinessDays.holiday?(next_maintenance)
      next_maintenance = JapaneseBusinessDays.previous_business_day(next_maintenance)
    end
    
    {
      equipment_name: equipment_name,
      last_maintenance: last_maintenance_date,
      next_maintenance: next_maintenance,
      interval_days: interval_days,
      days_until_maintenance: JapaneseBusinessDays.business_days_between(Date.today, next_maintenance)
    }
  end
  
  def generate_maintenance_calendar(year, month)
    # 指定月のメンテナンス予定を生成
    start_date = Date.new(year, month, 1)
    end_date = Date.new(year, month, -1)
    
    maintenance_dates = []
    current_date = start_date
    
    while current_date <= end_date
      if JapaneseBusinessDays.business_day?(current_date)
        # 設備ごとのメンテナンス周期をチェック
        equipment_list.each do |equipment|
          if maintenance_due?(equipment, current_date)
            maintenance_dates << {
              date: current_date,
              equipment: equipment[:name],
              type: equipment[:maintenance_type]
            }
          end
        end
      end
      current_date += 1
    end
    
    maintenance_dates
  end
  
  private
  
  def equipment_list
    [
      { name: "プレス機A", maintenance_type: "定期点検", cycle_days: 30 },
      { name: "溶接ロボットB", maintenance_type: "校正", cycle_days: 45 },
      { name: "塗装ライン", maintenance_type: "清掃", cycle_days: 15 },
      { name: "検査装置C", maintenance_type: "精度確認", cycle_days: 60 }
    ]
  end
  
  def maintenance_due?(equipment, date)
    # 簡略化された判定ロジック（実際はデータベースから取得）
    (date.day % equipment[:cycle_days]) == 0
  end
end

# メンテナンススケジュールの例
maintenance_scheduler = MaintenanceScheduler.new

# 各設備の次回メンテナンス予定
equipment_schedules = [
  { name: "プレス機A", last_maintenance: Date.new(2024, 1, 10), interval: 30 },
  { name: "溶接ロボットB", last_maintenance: Date.new(2024, 1, 5), interval: 45 },
  { name: "塗装ライン", last_maintenance: Date.new(2024, 1, 15), interval: 15 },
  { name: "検査装置C", last_maintenance: Date.new(2023, 12, 20), interval: 60 }
]

puts "設備メンテナンススケジュール:"
puts "設備名         | 前回実施   | 次回予定   | 周期   | 残り日数"
puts "-" * 60

equipment_schedules.each do |equipment|
  schedule = maintenance_scheduler.schedule_routine_maintenance(
    equipment[:name],
    equipment[:last_maintenance],
    equipment[:interval]
  )
  
  puts "#{schedule[:equipment_name].ljust(14)} | #{schedule[:last_maintenance]} | #{schedule[:next_maintenance]} | #{schedule[:interval_days].to_s.ljust(6)} | #{schedule[:days_until_maintenance]}日"
end

puts

# =============================================================================
# 3. 原材料調達スケジュール
# =============================================================================

puts "3. 原材料調達スケジュール"
puts "-" * 40

class ProcurementScheduler
  def initialize
    @suppliers = {
      "鋼材" => { lead_time: 7, order_cycle: 14 },
      "樹脂" => { lead_time: 3, order_cycle: 7 },
      "電子部品" => { lead_time: 10, order_cycle: 21 },
      "包装材" => { lead_time: 2, order_cycle: 5 }
    }
  end
  
  def calculate_order_schedule(material_name, required_date, safety_days = 2)
    supplier_info = @suppliers[material_name]
    return nil unless supplier_info
    
    # 安全在庫を考慮した必要日
    target_delivery = JapaneseBusinessDays.subtract_business_days(required_date, safety_days)
    
    # 発注日を計算（リードタイムを考慮）
    order_date = JapaneseBusinessDays.subtract_business_days(target_delivery, supplier_info[:lead_time])
    
    # 発注サイクルに合わせて調整
    adjusted_order_date = adjust_to_order_cycle(order_date, supplier_info[:order_cycle])
    
    # 実際の納期を再計算
    actual_delivery = JapaneseBusinessDays.add_business_days(adjusted_order_date, supplier_info[:lead_time])
    
    {
      material_name: material_name,
      required_date: required_date,
      target_delivery: target_delivery,
      order_date: adjusted_order_date,
      actual_delivery: actual_delivery,
      lead_time: supplier_info[:lead_time],
      safety_margin: JapaneseBusinessDays.business_days_between(actual_delivery, required_date)
    }
  end
  
  def generate_procurement_plan(production_schedule)
    procurement_plan = []
    
    production_schedule.each do |production|
      materials_needed = get_materials_for_product(production[:product_name])
      
      materials_needed.each do |material|
        order_info = calculate_order_schedule(
          material[:name],
          production[:production_start],
          material[:safety_days] || 2
        )
        
        if order_info
          procurement_plan << order_info.merge(
            product_name: production[:product_name],
            quantity_needed: material[:quantity]
          )
        end
      end
    end
    
    procurement_plan.sort_by { |item| item[:order_date] }
  end
  
  private
  
  def adjust_to_order_cycle(order_date, cycle_days)
    # 発注サイクルに合わせて最適な発注日を選択
    base_date = Date.new(2024, 1, 1)  # 基準日
    days_from_base = (order_date - base_date).to_i
    cycle_position = days_from_base % cycle_days
    
    if cycle_position == 0
      order_date
    else
      # 前回の発注日に調整
      JapaneseBusinessDays.subtract_business_days(order_date, cycle_position)
    end
  end
  
  def get_materials_for_product(product_name)
    # 製品ごとの必要材料（簡略化）
    case product_name
    when "製品A"
      [
        { name: "鋼材", quantity: 50, safety_days: 3 },
        { name: "樹脂", quantity: 20, safety_days: 1 }
      ]
    when "製品B"
      [
        { name: "鋼材", quantity: 80, safety_days: 3 },
        { name: "電子部品", quantity: 10, safety_days: 5 }
      ]
    when "製品C"
      [
        { name: "樹脂", quantity: 30, safety_days: 1 },
        { name: "包装材", quantity: 100, safety_days: 1 }
      ]
    else
      []
    end
  end
end

procurement_scheduler = ProcurementScheduler.new
procurement_plan = procurement_scheduler.generate_procurement_plan(schedules)

puts "原材料調達計画:"
puts "製品名 | 材料名     | 発注日     | 納期       | 必要日     | 安全余裕 | 数量"
puts "-" * 75

procurement_plan.each do |item|
  puts "#{item[:product_name].ljust(6)} | #{item[:material_name].ljust(10)} | #{item[:order_date]} | #{item[:actual_delivery]} | #{item[:required_date]} | #{item[:safety_margin].to_s.ljust(8)} | #{item[:quantity_needed]}"
end

puts

# =============================================================================
# 4. 品質管理スケジュール
# =============================================================================

puts "4. 品質管理スケジュール"
puts "-" * 40

class QualityControlScheduler
  def initialize
    @inspection_types = {
      "入荷検査" => { duration: 1, frequency: :daily },
      "工程検査" => { duration: 0.5, frequency: :per_batch },
      "最終検査" => { duration: 2, frequency: :per_product },
      "出荷検査" => { duration: 1, frequency: :daily }
    }
  end
  
  def schedule_inspections(production_schedule)
    inspection_schedule = []
    
    production_schedule.each do |production|
      # 入荷検査（生産開始前日）
      incoming_inspection = JapaneseBusinessDays.previous_business_day(production[:production_start])
      inspection_schedule << {
        date: incoming_inspection,
        type: "入荷検査",
        product: production[:product_name],
        duration: 1,
        inspector: assign_inspector("入荷検査", incoming_inspection)
      }
      
      # 工程検査（生産期間中）
      process_inspection_dates = calculate_process_inspection_dates(
        production[:production_start],
        production[:production_end]
      )
      
      process_inspection_dates.each do |date|
        inspection_schedule << {
          date: date,
          type: "工程検査",
          product: production[:product_name],
          duration: 0.5,
          inspector: assign_inspector("工程検査", date)
        }
      end
      
      # 最終検査（生産完了日）
      inspection_schedule << {
        date: production[:production_end],
        type: "最終検査",
        product: production[:product_name],
        duration: 2,
        inspector: assign_inspector("最終検査", production[:production_end])
      }
      
      # 出荷検査（出荷日当日）
      inspection_schedule << {
        date: production[:shipping_date],
        type: "出荷検査",
        product: production[:product_name],
        duration: 1,
        inspector: assign_inspector("出荷検査", production[:shipping_date])
      }
    end
    
    inspection_schedule.sort_by { |item| [item[:date], item[:type]] }
  end
  
  private
  
  def calculate_process_inspection_dates(start_date, end_date)
    dates = []
    current_date = start_date
    
    while current_date <= end_date
      if JapaneseBusinessDays.business_day?(current_date)
        dates << current_date
      end
      current_date += 1
    end
    
    # 2日に1回の工程検査
    dates.select.with_index { |_, index| index.even? }
  end
  
  def assign_inspector(inspection_type, date)
    # 簡略化された検査員アサインロジック
    inspectors = {
      "入荷検査" => ["田中", "佐藤"],
      "工程検査" => ["山田", "鈴木", "高橋"],
      "最終検査" => ["田中", "山田"],
      "出荷検査" => ["佐藤", "鈴木"]
    }
    
    available_inspectors = inspectors[inspection_type] || ["未定"]
    available_inspectors[date.day % available_inspectors.length]
  end
end

qc_scheduler = QualityControlScheduler.new
inspection_schedule = qc_scheduler.schedule_inspections(schedules)

puts "品質管理スケジュール:"
puts "日付       | 検査種別   | 製品名 | 所要時間 | 担当者"
puts "-" * 55

inspection_schedule.each do |inspection|
  duration_str = inspection[:duration] == 1 ? "1日" : "#{inspection[:duration]}日"
  puts "#{inspection[:date]} | #{inspection[:type].ljust(10)} | #{inspection[:product].ljust(6)} | #{duration_str.ljust(8)} | #{inspection[:inspector]}"
end

puts

# =============================================================================
# 5. 生産能力分析
# =============================================================================

puts "5. 生産能力分析"
puts "-" * 40

class CapacityAnalyzer
  def initialize
    @daily_capacity = {
      "製品A" => 20,  # 1日あたりの生産可能数
      "製品B" => 15,
      "製品C" => 30
    }
  end
  
  def analyze_monthly_capacity(year, month)
    business_days = get_business_days_in_month(year, month)
    
    analysis = {}
    @daily_capacity.each do |product, daily_capacity|
      monthly_capacity = daily_capacity * business_days.length
      analysis[product] = {
        business_days: business_days.length,
        daily_capacity: daily_capacity,
        monthly_capacity: monthly_capacity,
        business_days_list: business_days
      }
    end
    
    analysis
  end
  
  def calculate_production_feasibility(orders, year, month)
    capacity_analysis = analyze_monthly_capacity(year, month)
    feasibility_report = {}
    
    # 製品別の受注数量を集計
    order_summary = orders.group_by { |order| order[:product_name] }
                          .transform_values { |orders| orders.sum { |order| order[:quantity] } }
    
    order_summary.each do |product, total_quantity|
      capacity_info = capacity_analysis[product]
      next unless capacity_info
      
      feasible = total_quantity <= capacity_info[:monthly_capacity]
      utilization_rate = (total_quantity.to_f / capacity_info[:monthly_capacity] * 100).round(1)
      
      feasibility_report[product] = {
        ordered_quantity: total_quantity,
        monthly_capacity: capacity_info[:monthly_capacity],
        feasible: feasible,
        utilization_rate: utilization_rate,
        excess_quantity: feasible ? 0 : total_quantity - capacity_info[:monthly_capacity]
      }
    end
    
    feasibility_report
  end
  
  private
  
  def get_business_days_in_month(year, month)
    start_date = Date.new(year, month, 1)
    end_date = Date.new(year, month, -1)
    
    business_days = []
    current_date = start_date
    
    while current_date <= end_date
      if JapaneseBusinessDays.business_day?(current_date)
        business_days << current_date
      end
      current_date += 1
    end
    
    business_days
  end
end

# 2024年1月の生産能力分析
analyzer = CapacityAnalyzer.new
capacity_analysis = analyzer.analyze_monthly_capacity(2024, 1)

puts "2024年1月の生産能力分析:"
puts "製品名 | 営業日数 | 日産能力 | 月産能力"
puts "-" * 40

capacity_analysis.each do |product, info|
  puts "#{product.ljust(6)} | #{info[:business_days].to_s.ljust(8)} | #{info[:daily_capacity].to_s.ljust(8)} | #{info[:monthly_capacity]}"
end

# 受注実現可能性の分析
feasibility = analyzer.calculate_production_feasibility(orders, 2024, 1)

puts "\n受注実現可能性分析:"
puts "製品名 | 受注数量 | 月産能力 | 稼働率   | 実現可能 | 超過数量"
puts "-" * 60

feasibility.each do |product, info|
  feasible_str = info[:feasible] ? "可能" : "不可"
  puts "#{product.ljust(6)} | #{info[:ordered_quantity].to_s.ljust(8)} | #{info[:monthly_capacity].to_s.ljust(8)} | #{info[:utilization_rate].to_s.ljust(8)}% | #{feasible_str.ljust(8)} | #{info[:excess_quantity]}"
end

# 設定をリセット
JapaneseBusinessDays.configuration.reset!

puts
puts "=== 製造業サンプル完了 ==="