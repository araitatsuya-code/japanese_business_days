# frozen_string_literal: true

# Rails統合の使用例
# このファイルは、JapaneseBusinessDaysがRails環境でどのように動作するかを示します

# Rails環境のシミュレーション
module Rails
  def self.env
    'development'
  end
end

# ActiveSupportのシミュレーション
module ActiveSupport
  class TimeWithZone
    attr_reader :time, :time_zone, :hour, :min, :sec

    def initialize(time, time_zone)
      @time = time
      @time_zone = time_zone
      @hour = time.hour
      @min = time.min
      @sec = time.sec
    end

    def to_date
      @time.to_date
    end

    def year
      @time.year
    end

    def month
      @time.month
    end

    def day
      @time.day
    end
  end

  class TimeZone
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def local(year, month, day, hour = 0, min = 0, sec = 0)
      time = Time.new(year, month, day, hour, min, sec)
      TimeWithZone.new(time, self)
    end
  end
end

# ActiveRecordのシミュレーション
module ActiveRecord
  class Base
    attr_accessor :created_at, :updated_at, :due_date, :start_date

    def initialize(attributes = {})
      attributes.each do |key, value|
        send("#{key}=", value)
      end
    end
  end
end

# JapaneseBusinessDaysをロード
require_relative '../lib/japanese_business_days'

# Rails統合を手動で有効化（通常は自動）
Date.include(JapaneseBusinessDays::DateExtensions)
Time.include(JapaneseBusinessDays::DateExtensions)
DateTime.include(JapaneseBusinessDays::DateExtensions)
ActiveSupport::TimeWithZone.include(JapaneseBusinessDays::DateExtensions)

puts "=== Rails統合の使用例 ==="
puts

# 1. 基本的な日付操作
puts "1. 基本的な日付操作"
date = Date.new(2024, 1, 15) # 月曜日
puts "基準日: #{date} (#{%w[日 月 火 水 木 金 土][date.wday]}曜日)"
puts "営業日?: #{date.business_day?}"
puts "5営業日後: #{date.add_business_days(5)}"
puts "3営業日前: #{date.subtract_business_days(3)}"
puts

# 2. Time オブジェクトでの操作
puts "2. Time オブジェクトでの操作"
time = Time.new(2024, 1, 15, 14, 30, 0)
puts "基準時刻: #{time}"
puts "営業日?: #{time.business_day?}"
next_business_time = time.add_business_days(2)
puts "2営業日後: #{next_business_time}"
puts "時刻が保持されている: #{next_business_time.hour}:#{next_business_time.min}"
puts

# 3. ActiveSupport::TimeWithZone での操作
puts "3. ActiveSupport::TimeWithZone での操作"
jst_zone = ActiveSupport::TimeZone.new('Asia/Tokyo')
time_with_zone = jst_zone.local(2024, 1, 15, 9, 0, 0)
puts "基準時刻（JST）: #{time_with_zone.time} (#{time_with_zone.time_zone.name})"
puts "営業日?: #{time_with_zone.business_day?}"
next_business_tz = time_with_zone.add_business_days(1)
puts "1営業日後: #{next_business_tz.time} (#{next_business_tz.time_zone.name})"
puts

# 4. ActiveRecord モデルでの使用例
puts "4. ActiveRecord モデルでの使用例"

# プロジェクトモデルの例
class Project < ActiveRecord::Base
  def calculate_deadline(business_days_from_start)
    start_date.add_business_days(business_days_from_start)
  end

  def days_until_due
    JapaneseBusinessDays.business_days_between(Date.current, due_date)
  end

  def overdue?
    due_date < Date.current && !due_date.business_day?
  end
end

# 請求書モデルの例
class Invoice < ActiveRecord::Base
  def payment_due_date
    # 請求日から30営業日後
    created_at.add_business_days(30)
  end

  def is_payment_overdue?
    payment_due_date < Time.current
  end
end

# プロジェクトの例
project = Project.new(
  start_date: Date.new(2024, 1, 15),
  due_date: Date.new(2024, 2, 15)
)

puts "プロジェクト開始日: #{project.start_date}"
puts "プロジェクト期限: #{project.due_date}"
puts "10営業日後の予定日: #{project.calculate_deadline(10)}"
puts

# 請求書の例
invoice = Invoice.new(
  created_at: Time.new(2024, 1, 15, 10, 0, 0)
)

puts "請求書作成日時: #{invoice.created_at}"
puts "支払期限: #{invoice.payment_due_date}"
puts

# 5. 祝日との組み合わせ
puts "5. 祝日との組み合わせ"
new_years_eve = Date.new(2023, 12, 31) # 日曜日
new_years_day = Date.new(2024, 1, 1)   # 元日（祝日）

puts "大晦日 (#{new_years_eve}): 営業日? #{new_years_eve.business_day?}"
puts "元日 (#{new_years_day}): 営業日? #{new_years_day.business_day?}, 祝日? #{new_years_day.holiday?}"
puts "元日の次の営業日: #{new_years_day.next_business_day}"
puts

# 6. カスタム設定との組み合わせ
puts "6. カスタム設定との組み合わせ"
JapaneseBusinessDays.configure do |config|
  # 会社の創立記念日を追加の休日に設定
  config.add_holiday(Date.new(2024, 3, 15))
end

company_anniversary = Date.new(2024, 3, 15)
puts "会社創立記念日 (#{company_anniversary}): 営業日? #{company_anniversary.business_day?}"
puts

# 7. パフォーマンステスト
puts "7. パフォーマンステスト"
start_time = Time.now

# 100個のActiveRecordオブジェクトで営業日計算
records = 100.times.map do |i|
  Project.new(start_date: Date.new(2024, 1, 15 + (i % 10)))
end

results = records.map { |record| record.start_date.add_business_days(5) }

end_time = Time.now
puts "100件の営業日計算時間: #{((end_time - start_time) * 1000).round(2)}ms"
puts "すべて正常に計算完了: #{results.all? { |r| r.is_a?(Date) }}"
puts

puts "=== Rails統合の使用例完了 ==="