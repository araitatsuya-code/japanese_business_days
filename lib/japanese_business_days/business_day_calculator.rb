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
    # @raise [InvalidArgumentError] 無効な引数の場合
    def business_day?(date)
      validate_date!(date)
      
      # カスタム営業日として設定されている場合は営業日
      return true if @configuration.additional_business_day?(date)
      
      # 非営業日（週末、祝日、カスタム非営業日）の場合は営業日ではない
      return false if non_business_day?(date)
      
      # 上記に該当しない場合は営業日
      true
    rescue => e
      handle_calculation_error(e, "business day calculation for #{date}")
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
    # @param date [Date] 判定する日付
    # @return [Boolean] 週末の場合true
    def weekend?(date)
      @configuration.weekend_day?(date.wday)
    end

    # 非営業日判定
    # @param date [Date] 判定する日付
    # @return [Boolean] 非営業日の場合true
    def non_business_day?(date)
      # カスタム営業日として設定されている場合は営業日扱い
      return false if @configuration.additional_business_day?(date)
      
      # 週末判定
      return true if weekend?(date)
      
      # 祝日判定
      return true if @holiday_calculator.holiday?(date)
      
      # カスタム非営業日判定
      return true if @configuration.additional_holiday?(date)
      
      false
    end

    # 日付の検証
    # @param date [Date] 検証する日付
    # @raise [InvalidArgumentError] 無効な日付の場合
    def validate_date!(date)
      unless date.is_a?(Date)
        raise InvalidArgumentError, "Date must be a Date object, got #{date.class}"
      end
    end

    # エラーハンドリング
    # @param error [Exception] 発生したエラー
    # @param context [String] エラーが発生したコンテキスト
    # @raise [Error] 適切なエラーを再発生
    def handle_calculation_error(error, context)
      case error
      when InvalidArgumentError, InvalidDateError
        raise error
      when ArgumentError
        raise InvalidArgumentError, "Invalid argument in #{context}: #{error.message}"
      when StandardError
        raise Error, "Unexpected error in #{context}: #{error.message}"
      end
    end
  end
end