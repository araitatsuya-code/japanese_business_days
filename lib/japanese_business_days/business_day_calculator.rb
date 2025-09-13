# frozen_string_literal: true

module JapaneseBusinessDays
  # 営業日計算のコアロジックを担当するクラス
  class BusinessDayCalculator
    # @param holiday_calculator [HolidayCalculator] 祝日計算器
    # @param configuration [Configuration] 設定オブジェクト
    def initialize(holiday_calculator, configuration)
      @holiday_calculator = holiday_calculator
      @configuration = configuration
    end

    # 営業日判定
    # @param date [Date] 判定する日付
    # @return [Boolean] 営業日の場合true
    def business_day?(date)
      raise NotImplementedError, "This method will be implemented in task 5.1"
    end

    # 営業日数計算
    # @param start_date [Date] 開始日
    # @param end_date [Date] 終了日
    # @return [Integer] 営業日数
    def business_days_between(start_date, end_date)
      raise NotImplementedError, "This method will be implemented in task 5.2"
    end

    # 営業日加算
    # @param date [Date] 基準日
    # @param days [Integer] 加算する営業日数
    # @return [Date] 計算結果の日付
    def add_business_days(date, days)
      raise NotImplementedError, "This method will be implemented in task 5.3"
    end

    # 営業日減算
    # @param date [Date] 基準日
    # @param days [Integer] 減算する営業日数
    # @return [Date] 計算結果の日付
    def subtract_business_days(date, days)
      raise NotImplementedError, "This method will be implemented in task 5.3"
    end

    # 次の営業日
    # @param date [Date] 基準日
    # @return [Date] 次の営業日
    def next_business_day(date)
      raise NotImplementedError, "This method will be implemented in task 5.4"
    end

    # 前の営業日
    # @param date [Date] 基準日
    # @return [Date] 前の営業日
    def previous_business_day(date)
      raise NotImplementedError, "This method will be implemented in task 5.4"
    end

    private

    # 週末判定
    def weekend?(date)
      raise NotImplementedError, "This method will be implemented in task 5.1"
    end

    # 非営業日判定
    def non_business_day?(date)
      raise NotImplementedError, "This method will be implemented in task 5.1"
    end

    # 日付正規化
    def normalize_date(date)
      raise NotImplementedError, "This method will be implemented in task 8.1"
    end
  end
end