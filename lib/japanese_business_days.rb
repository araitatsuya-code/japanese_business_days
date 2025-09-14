# frozen_string_literal: true

require_relative "japanese_business_days/version"
require_relative "japanese_business_days/errors"
require_relative "japanese_business_days/holiday"
require_relative "japanese_business_days/configuration"
require_relative "japanese_business_days/cache_manager"
require_relative "japanese_business_days/holiday_calculator"
require_relative "japanese_business_days/business_day_calculator"
require_relative "japanese_business_days/date_extensions"

module JapaneseBusinessDays
  # 日本の祝日定数
  FIXED_HOLIDAYS = {
    [1, 1]   => "元日",
    [2, 11]  => "建国記念の日",
    [4, 29]  => "昭和の日",
    [5, 3]   => "憲法記念日",
    [5, 4]   => "みどりの日",
    [5, 5]   => "こどもの日",
    [8, 11]  => "山の日",
    [11, 3]  => "文化の日",
    [11, 23] => "勤労感謝の日",
    [12, 23] => "天皇誕生日"
  }.freeze

  HAPPY_MONDAY_HOLIDAYS = {
    [1, 2] => "成人の日",      # 1月第2月曜日
    [7, 3] => "海の日",       # 7月第3月曜日
    [9, 3] => "敬老の日",     # 9月第3月曜日
    [10, 2] => "スポーツの日"  # 10月第2月曜日
  }.freeze

  DEFAULT_WEEKEND_DAYS = [0, 6].freeze # 日曜日、土曜日

  class << self
    # 設定オブジェクト
    # @return [Configuration] 現在の設定
    def configuration
      @configuration ||= Configuration.new
    end

    # 設定ブロック
    # @yield [Configuration] 設定オブジェクト
    def configure
      yield(configuration) if block_given?
    end

    # 営業日数計算
    # @param start_date [Date, Time, DateTime, String] 開始日
    # @param end_date [Date, Time, DateTime, String] 終了日
    # @return [Integer] 営業日数
    def business_days_between(start_date, end_date)
      business_day_calculator.business_days_between(
        normalize_date(start_date),
        normalize_date(end_date)
      )
    end

    # 営業日判定
    # @param date [Date, Time, DateTime, String] 判定する日付
    # @return [Boolean] 営業日の場合true
    def business_day?(date)
      business_day_calculator.business_day?(normalize_date(date))
    end

    # 祝日判定
    # @param date [Date, Time, DateTime, String] 判定する日付
    # @return [Boolean] 祝日の場合true
    def holiday?(date)
      holiday_calculator.holiday?(normalize_date(date))
    end

    # 年間祝日取得
    # @param year [Integer] 対象年
    # @return [Array<Holiday>] その年の祝日リスト
    def holidays_in_year(year)
      holiday_calculator.holidays_in_year(year)
    end

    private

    # 祝日計算器のインスタンス
    # @return [HolidayCalculator]
    def holiday_calculator
      @holiday_calculator ||= HolidayCalculator.new
    end

    # 営業日計算器のインスタンス
    # @return [BusinessDayCalculator]
    def business_day_calculator
      @business_day_calculator ||= BusinessDayCalculator.new(
        holiday_calculator,
        configuration
      )
    end

    # 日付正規化（実装は後のタスクで行う）
    # @param date [Date, Time, DateTime, String] 正規化する日付
    # @return [Date] 正規化された日付
    def normalize_date(date)
      case date
      when Date
        date
      when Time, DateTime
        date.to_date
      when String
        Date.parse(date)
      else
        raise InvalidArgumentError, "Invalid date type: #{date.class}"
      end
    rescue ArgumentError => e
      raise InvalidDateError, "Invalid date format: #{date} - #{e.message}"
    end
  end
end

# Rails統合（Railsが検出された場合の自動拡張）
if defined?(Rails)
  Date.include(JapaneseBusinessDays::DateExtensions)
  Time.include(JapaneseBusinessDays::DateExtensions)
  DateTime.include(JapaneseBusinessDays::DateExtensions)
  
  # ActiveSupportが利用可能な場合の追加統合
  if defined?(ActiveSupport::TimeWithZone)
    ActiveSupport::TimeWithZone.include(JapaneseBusinessDays::DateExtensions)
  end
end
