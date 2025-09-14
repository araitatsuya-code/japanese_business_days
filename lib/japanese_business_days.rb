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
    # @raise [InvalidArgumentError] ブロックが提供されない場合
    def configure
      unless block_given?
        error = InvalidArgumentError.new(
          "Configuration block is required",
          parameter_name: "block",
          suggestions: [
            "Use JapaneseBusinessDays.configure { |config| ... }",
            "Provide a block that yields the configuration object"
          ]
        )
        Logging.log_error(error)
        raise error
      end
      
      Logging.debug("Starting configuration", { method: "configure" })
      
      begin
        yield(configuration)
        Logging.info("Configuration completed successfully")
      rescue => e
        Logging.log_error(e, { method: "configure" })
        
        case e
        when InvalidArgumentError, InvalidDateError, ConfigurationError
          raise e
        else
          enhanced_error = ConfigurationError.new(
            "Configuration failed: #{e.message}",
            context: { original_error: e.class.name },
            suggestions: [
              "Check the configuration block for syntax errors",
              "Ensure all configuration values are of the correct type",
              "Review the documentation for valid configuration options"
            ]
          )
          raise enhanced_error
        end
      end
      
      # 設定変更後にキャッシュをクリア
      reset_calculators!
      Logging.debug("Calculators reset after configuration change")
    end

    # 設定リセット（テスト用）
    # @api private
    def reset_configuration!
      @configuration = Configuration.new
      reset_calculators!
    end

    # 営業日数計算
    # @param start_date [Date, Time, DateTime, String] 開始日
    # @param end_date [Date, Time, DateTime, String] 終了日
    # @return [Integer] 営業日数
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型の場合
    # @raise [InvalidDateError] 日付形式が無効な場合
    def business_days_between(start_date, end_date)
      Logging.debug("Calculating business days between dates", {
        method: "business_days_between",
        start_date: start_date,
        end_date: end_date
      })
      
      validate_not_nil!(start_date, "start_date")
      validate_not_nil!(end_date, "end_date")
      
      begin
        normalized_start = normalize_date(start_date)
        normalized_end = normalize_date(end_date)
        
        result = business_day_calculator.business_days_between(normalized_start, normalized_end)
        
        Logging.debug("Business days calculation completed", {
          method: "business_days_between",
          result: result,
          normalized_start: normalized_start,
          normalized_end: normalized_end
        })
        
        result
      rescue => e
        Logging.log_error(e, {
          method: "business_days_between",
          start_date: start_date,
          end_date: end_date
        })
        raise
      end
    end

    # 営業日判定
    # @param date [Date, Time, DateTime, String] 判定する日付
    # @return [Boolean] 営業日の場合true
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型の場合
    # @raise [InvalidDateError] 日付形式が無効な場合
    def business_day?(date)
      validate_not_nil!(date, "date")
      normalized_date = normalize_date(date)
      business_day_calculator.business_day?(normalized_date)
    end

    # 祝日判定
    # @param date [Date, Time, DateTime, String] 判定する日付
    # @return [Boolean] 祝日の場合true
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型の場合
    # @raise [InvalidDateError] 日付形式が無効な場合
    def holiday?(date)
      validate_not_nil!(date, "date")
      normalized_date = normalize_date(date)
      holiday_calculator.holiday?(normalized_date)
    end

    # 年間祝日取得
    # @param year [Integer] 対象年
    # @return [Array<Holiday>] その年の祝日リスト
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型・範囲の場合
    def holidays_in_year(year)
      validate_not_nil!(year, "year")
      validate_year!(year)
      holiday_calculator.holidays_in_year(year)
    end

    # 営業日加算
    # @param date [Date, Time, DateTime, String] 基準日
    # @param days [Integer] 加算する営業日数
    # @return [Date] 計算結果の日付
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型の場合
    # @raise [InvalidDateError] 日付形式が無効な場合
    def add_business_days(date, days)
      validate_not_nil!(date, "date")
      validate_not_nil!(days, "days")
      validate_integer!(days, "days")
      
      normalized_date = normalize_date(date)
      result = business_day_calculator.add_business_days(normalized_date, days)
      normalize_date(result)
    end

    # 営業日減算
    # @param date [Date, Time, DateTime, String] 基準日
    # @param days [Integer] 減算する営業日数
    # @return [Date] 計算結果の日付
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型の場合
    # @raise [InvalidDateError] 日付形式が無効な場合
    def subtract_business_days(date, days)
      validate_not_nil!(date, "date")
      validate_not_nil!(days, "days")
      validate_integer!(days, "days")
      
      normalized_date = normalize_date(date)
      result = business_day_calculator.subtract_business_days(normalized_date, days)
      normalize_date(result)
    end

    # 次の営業日
    # @param date [Date, Time, DateTime, String] 基準日
    # @return [Date] 次の営業日
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型の場合
    # @raise [InvalidDateError] 日付形式が無効な場合
    def next_business_day(date)
      validate_not_nil!(date, "date")
      normalized_date = normalize_date(date)
      result = business_day_calculator.next_business_day(normalized_date)
      normalize_date(result)
    end

    # 前の営業日
    # @param date [Date, Time, DateTime, String] 基準日
    # @return [Date] 前の営業日
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型の場合
    # @raise [InvalidDateError] 日付形式が無効な場合
    def previous_business_day(date)
      validate_not_nil!(date, "date")
      normalized_date = normalize_date(date)
      result = business_day_calculator.previous_business_day(normalized_date)
      normalize_date(result)
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

    # 計算器のリセット（設定変更時に呼び出される）
    # @api private
    def reset_calculators!
      @holiday_calculator = nil
      @business_day_calculator = nil
    end

    # 日付正規化
    # @param date [Date, Time, DateTime, String] 正規化する日付
    # @return [Date] 正規化された日付
    # @raise [InvalidArgumentError] 無効な日付型の場合
    # @raise [InvalidDateError] 無効な日付形式の場合
    def normalize_date(date)
      case date
      when DateTime, Time
        date.to_date
      when Date
        date
      when String
        validate_date_string!(date)
        Date.parse(date)
      else
        error = InvalidArgumentError.new(
          "Invalid date type: #{date.class}. Expected Date, Time, DateTime, or String",
          parameter_name: "date",
          received_value: date,
          expected_type: "Date, Time, DateTime, or String"
        )
        Logging.log_error(error)
        raise error
      end
    rescue ArgumentError => e
      error = InvalidDateError.new(
        "Invalid date format: #{date} - #{e.message}",
        invalid_date: date,
        context: { parse_error: e.message }
      )
      Logging.log_error(error)
      raise error
    end

    # nil値の検証
    # @param value [Object] 検証する値
    # @param param_name [String] パラメータ名
    # @raise [InvalidArgumentError] 値がnilの場合
    def validate_not_nil!(value, param_name)
      if value.nil?
        error = InvalidArgumentError.new(
          "#{param_name} cannot be nil",
          parameter_name: param_name,
          received_value: nil
        )
        Logging.log_error(error)
        raise error
      end
    end

    # 整数の検証
    # @param value [Object] 検証する値
    # @param param_name [String] パラメータ名
    # @raise [InvalidArgumentError] 値が整数でない場合
    def validate_integer!(value, param_name)
      unless value.is_a?(Integer)
        error = InvalidArgumentError.new(
          "#{param_name} must be an Integer, got #{value.class}",
          parameter_name: param_name,
          received_value: value,
          expected_type: Integer
        )
        Logging.log_error(error)
        raise error
      end
    end

    # 年の検証
    # @param year [Object] 検証する年
    # @raise [InvalidArgumentError] 無効な年の場合
    def validate_year!(year)
      unless year.is_a?(Integer)
        error = InvalidArgumentError.new(
          "Year must be an Integer, got #{year.class}",
          parameter_name: "year",
          received_value: year,
          expected_type: Integer
        )
        Logging.log_error(error)
        raise error
      end
      
      unless (1000..9999).include?(year)
        error = InvalidArgumentError.new(
          "Year must be between 1000 and 9999, got #{year}",
          parameter_name: "year",
          received_value: year,
          context: { valid_range: "1000-9999" }
        )
        Logging.log_error(error)
        raise error
      end
    end

    # 日付文字列の検証
    # @param date_string [String] 検証する日付文字列
    # @raise [InvalidArgumentError] 空文字列の場合
    def validate_date_string!(date_string)
      if date_string.empty?
        error = InvalidArgumentError.new(
          "Date string cannot be empty",
          parameter_name: "date_string",
          received_value: date_string
        )
        Logging.log_error(error)
        raise error
      end
      
      if date_string.strip.empty?
        error = InvalidArgumentError.new(
          "Date string cannot be blank",
          parameter_name: "date_string",
          received_value: date_string
        )
        Logging.log_error(error)
        raise error
      end
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
