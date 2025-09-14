# frozen_string_literal: true

require "spec_helper"

# Rails統合テスト用のモックセットアップ
module Rails
  def self.env
    "test"
  end
end

# ActiveSupportのモック
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

# ActiveRecordのモック
module ActiveRecord
  class Base
    attr_accessor :created_at, :updated_at, :due_date

    def initialize(attributes = {})
      attributes.each do |key, value|
        send("#{key}=", value)
      end
    end
  end
end

RSpec.describe "Rails Integration" do
  before(:all) do
    # Rails統合を強制的に有効化
    Date.include(JapaneseBusinessDays::DateExtensions)
    Time.include(JapaneseBusinessDays::DateExtensions)
    DateTime.include(JapaneseBusinessDays::DateExtensions)
    ActiveSupport::TimeWithZone.include(JapaneseBusinessDays::DateExtensions)
  end

  describe "Date class extensions" do
    let(:date) { Date.new(2024, 1, 15) } # 月曜日（営業日）

    it "Date オブジェクトで営業日メソッドが使用できる" do
      expect(date).to respond_to(:business_day?)
      expect(date).to respond_to(:add_business_days)
      expect(date).to respond_to(:subtract_business_days)
      expect(date).to respond_to(:next_business_day)
      expect(date).to respond_to(:previous_business_day)
      expect(date).to respond_to(:holiday?)
    end

    it "営業日判定が正しく動作する" do
      expect(date.business_day?).to be true
    end

    it "営業日加算が正しく動作する" do
      result = date.add_business_days(5)
      expect(result).to be_a(Date)
      expect(result).to eq(Date.new(2024, 1, 22)) # 5営業日後
    end
  end

  describe "Time class extensions" do
    let(:time) { Time.new(2024, 1, 15, 10, 30, 0) } # 月曜日 10:30

    it "Time オブジェクトで営業日メソッドが使用できる" do
      expect(time).to respond_to(:business_day?)
      expect(time).to respond_to(:add_business_days)
    end

    it "営業日加算で時刻情報が保持される" do
      result = time.add_business_days(1)
      expect(result).to be_a(Time)
      expect(result.hour).to eq(10)
      expect(result.min).to eq(30)
      expect(result.sec).to eq(0)
    end
  end

  describe "DateTime class extensions" do
    let(:datetime) { DateTime.new(2024, 1, 15, 14, 45, 30) } # 月曜日 14:45:30

    it "DateTime オブジェクトで営業日メソッドが使用できる" do
      expect(datetime).to respond_to(:business_day?)
      expect(datetime).to respond_to(:subtract_business_days)
    end

    it "営業日減算で時刻情報が保持される" do
      result = datetime.subtract_business_days(2)
      expect(result).to be_a(DateTime)
      expect(result.hour).to eq(14)
      expect(result.min).to eq(45)
      expect(result.sec).to eq(30)
    end
  end

  describe "ActiveSupport::TimeWithZone integration" do
    let(:jst_zone) { ActiveSupport::TimeZone.new("Asia/Tokyo") }
    let(:time_with_zone) do
      jst_zone.local(2024, 1, 15, 9, 0, 0) # 月曜日 9:00 JST
    end

    it "TimeWithZone オブジェクトで営業日メソッドが使用できる" do
      expect(time_with_zone).to respond_to(:business_day?)
      expect(time_with_zone).to respond_to(:add_business_days)
      expect(time_with_zone).to respond_to(:next_business_day)
    end

    it "営業日判定が正しく動作する" do
      expect(time_with_zone.business_day?).to be true
    end

    it "営業日加算でタイムゾーンと時刻情報が保持される" do
      result = time_with_zone.add_business_days(3)
      expect(result).to be_a(ActiveSupport::TimeWithZone)
      expect(result.time_zone).to eq(jst_zone)
      expect(result.hour).to eq(9)
      expect(result.min).to eq(0)
      expect(result.sec).to eq(0)
    end

    it "次の営業日でタイムゾーンが保持される" do
      friday = jst_zone.local(2024, 1, 19, 15, 30, 0) # 金曜日 15:30
      result = friday.next_business_day
      expect(result).to be_a(ActiveSupport::TimeWithZone)
      expect(result.time_zone).to eq(jst_zone)
      expect(result.to_date).to eq(Date.new(2024, 1, 22)) # 次の月曜日
    end
  end

  describe "ActiveRecord attribute integration" do
    let(:model_class) do
      Class.new(ActiveRecord::Base) do
        def self.name
          "TestModel"
        end
      end
    end

    let(:record) do
      model_class.new(
        created_at: Time.new(2024, 1, 15, 10, 0, 0),
        due_date: Date.new(2024, 1, 20)
      )
    end

    it "ActiveRecord の日付属性で営業日メソッドが使用できる" do
      expect(record.created_at).to respond_to(:business_day?)
      expect(record.due_date).to respond_to(:add_business_days)
    end

    it "ActiveRecord の日付属性で営業日計算が正しく動作する" do
      expect(record.created_at.business_day?).to be true
      expect(record.due_date.business_day?).to be false # 土曜日
    end

    it "ActiveRecord の日付属性で営業日加算が動作する" do
      new_due_date = record.due_date.add_business_days(5)
      expect(new_due_date).to be_a(Date)
      expect(new_due_date).to eq(Date.new(2024, 1, 26)) # 5営業日後（土曜日から）
    end

    it "ActiveRecord の Time 属性で時刻情報が保持される" do
      next_business_time = record.created_at.add_business_days(1)
      expect(next_business_time).to be_a(Time)
      expect(next_business_time.hour).to eq(10)
      expect(next_business_time.min).to eq(0)
    end
  end

  describe "Rails timezone handling" do
    let(:utc_zone) { ActiveSupport::TimeZone.new("UTC") }
    let(:jst_zone) { ActiveSupport::TimeZone.new("Asia/Tokyo") }

    context "UTC タイムゾーン" do
      let(:utc_time) { utc_zone.local(2024, 1, 15, 12, 0, 0) }

      it "UTC タイムゾーンが保持される" do
        result = utc_time.add_business_days(1)
        expect(result.time_zone).to eq(utc_zone)
      end
    end

    context "JST タイムゾーン" do
      let(:jst_time) { jst_zone.local(2024, 1, 15, 21, 0, 0) }

      it "JST タイムゾーンが保持される" do
        result = jst_time.subtract_business_days(2)
        expect(result.time_zone).to eq(jst_zone)
      end
    end

    it "異なるタイムゾーンでも同じ日付なら同じ営業日判定結果" do
      utc_monday = utc_zone.local(2024, 1, 15, 0, 0, 0)
      jst_monday = jst_zone.local(2024, 1, 15, 9, 0, 0)

      expect(utc_monday.business_day?).to eq(jst_monday.business_day?)
    end
  end

  describe "Edge cases with Rails integration" do
    it "祝日でのタイムゾーン処理" do
      jst_zone = ActiveSupport::TimeZone.new("Asia/Tokyo")
      new_years_day = jst_zone.local(2024, 1, 1, 12, 0, 0) # 元日

      expect(new_years_day.holiday?).to be true
      expect(new_years_day.business_day?).to be false

      next_business = new_years_day.next_business_day
      expect(next_business.time_zone).to eq(jst_zone)
      expect(next_business.to_date).to eq(Date.new(2024, 1, 2)) # 次の営業日
    end

    it "週末でのタイムゾーン処理" do
      jst_zone = ActiveSupport::TimeZone.new("Asia/Tokyo")
      saturday = jst_zone.local(2024, 1, 20, 15, 30, 0) # 土曜日

      expect(saturday.business_day?).to be false

      next_business = saturday.next_business_day
      expect(next_business.time_zone).to eq(jst_zone)
      expect(next_business.to_date).to eq(Date.new(2024, 1, 22)) # 月曜日
    end

    it "nil 値の処理" do
      expect do
        nil.business_day?
      end.to raise_error(NoMethodError)
    end
  end

  describe "Performance with Rails objects" do
    let(:jst_zone) { ActiveSupport::TimeZone.new("Asia/Tokyo") }

    it "大量の TimeWithZone オブジェクトでの営業日計算が効率的" do
      times = Array.new(30) { |i| jst_zone.local(2024, 1, 15, 10 + (i % 12), 0, 0) }

      start_time = Time.now
      results = times.map(&:business_day?)
      end_time = Time.now

      expect(end_time - start_time).to be < 1.0 # 1秒以内
      expect(results).to all(satisfy { |result| [true, false].include?(result) })
    end

    it "ActiveRecord オブジェクトでの営業日加算が効率的" do
      records = Array.new(30) do |i|
        day = 15 + (i % 10) # 15日から24日まで
        ActiveRecord::Base.new(due_date: Date.new(2024, 1, day))
      end

      start_time = Time.now
      results = records.map { |r| r.due_date.add_business_days(5) }
      end_time = Time.now

      expect(end_time - start_time).to be < 0.5 # 0.5秒以内
      expect(results).to all(be_a(Date))
    end
  end
end
