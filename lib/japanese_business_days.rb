# frozen_string_literal: true

require_relative "japanese_business_days/version"
require_relative "japanese_business_days/errors"
require_relative "japanese_business_days/holiday"
require_relative "japanese_business_days/configuration"
require_relative "japanese_business_days/cache_manager"
require_relative "japanese_business_days/holiday_calculator"
require_relative "japanese_business_days/business_day_calculator"
require_relative "japanese_business_days/date_extensions"

# JapaneseBusinessDays - 日本の祝日・土日を考慮した営業日計算ライブラリ
#
# このgemは、日本の祝日・土日・カスタムビジネスルールを考慮した包括的な営業日計算機能を提供します。
# 特に金融・経理・業務システムで使用されるRailsアプリケーションにおいて、
# 日本の営業日計算の決定版ソリューションとして機能します。
#
# @example 基本的な使用方法
#   # 営業日数の計算
#   JapaneseBusinessDays.business_days_between(Date.new(2024, 1, 1), Date.new(2024, 1, 10))
#   # => 6
#
#   # 営業日判定
#   JapaneseBusinessDays.business_day?(Date.new(2024, 1, 1))  # 元日
#   # => false
#
#   # 祝日判定
#   JapaneseBusinessDays.holiday?(Date.new(2024, 1, 1))
#   # => true
#
#   # 営業日の加算・減算
#   JapaneseBusinessDays.add_business_days(Date.new(2024, 1, 5), 3)
#   # => Date.new(2024, 1, 10)
#
# @example カスタム設定
#   JapaneseBusinessDays.configure do |config|
#     # カスタム祝日を追加
#     config.add_holiday(Date.new(2024, 12, 31))
#     
#     # 特定の祝日を営業日として扱う
#     config.add_business_day(Date.new(2024, 1, 1))
#     
#     # 週末の定義を変更（土曜日のみを週末とする）
#     config.weekend_days = [6]
#   end
#
# @example Rails統合
#   # Date/Time/DateTimeクラスの拡張メソッドが自動的に利用可能
#   Date.today.business_day?
#   Date.today.add_business_days(5)
#   Date.today.next_business_day
#
# @author JapaneseBusinessDays Team
# @version 0.1.0
# @since 0.1.0
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
    # 現在の設定オブジェクトを取得します
    #
    # @return [Configuration] 現在の設定オブジェクト
    # @example 設定の確認
    #   config = JapaneseBusinessDays.configuration
    #   puts config.weekend_days  # => [0, 6]
    # @since 0.1.0
    def configuration
      @configuration ||= Configuration.new
    end

    # ライブラリの設定を行います
    #
    # ブロックを使用してカスタム祝日、営業日、週末の定義などを設定できます。
    # 設定変更後は内部キャッシュが自動的にクリアされ、新しい設定が適用されます。
    #
    # @yield [Configuration] 設定オブジェクト
    # @yieldparam config [Configuration] 設定を変更するためのオブジェクト
    # @raise [InvalidArgumentError] ブロックが提供されない場合
    # @raise [ConfigurationError] 設定処理中にエラーが発生した場合
    # @example 基本的な設定
    #   JapaneseBusinessDays.configure do |config|
    #     # カスタム祝日を追加
    #     config.add_holiday(Date.new(2024, 12, 31))
    #     
    #     # 特定の祝日を営業日として扱う
    #     config.add_business_day(Date.new(2024, 1, 1))
    #     
    #     # 週末を土曜日のみに変更
    #     config.weekend_days = [6]
    #   end
    # @example 複数の祝日を一括設定
    #   JapaneseBusinessDays.configure do |config|
    #     config.additional_holidays = [
    #       Date.new(2024, 12, 30),
    #       Date.new(2024, 12, 31)
    #     ]
    #   end
    # @since 0.1.0
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

    # 2つの日付間の営業日数を計算します
    #
    # 開始日と終了日の間にある営業日の数を返します。土日、日本の祝日、
    # カスタム設定された非営業日は除外されます。開始日と終了日は計算に含まれません。
    #
    # @param start_date [Date, Time, DateTime, String] 開始日
    # @param end_date [Date, Time, DateTime, String] 終了日
    # @return [Integer] 営業日数（開始日が終了日より後の場合は負の値）
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型の場合
    # @raise [InvalidDateError] 日付形式が無効な場合
    # @example 基本的な使用方法
    #   # 2024年1月1日から1月10日までの営業日数
    #   JapaneseBusinessDays.business_days_between(Date.new(2024, 1, 1), Date.new(2024, 1, 10))
    #   # => 6 (1/2, 1/4, 1/5, 1/9, 1/10の5日間。1/1は元日、1/6-1/8は土日月)
    # @example 文字列での日付指定
    #   JapaneseBusinessDays.business_days_between('2024-01-01', '2024-01-10')
    #   # => 6
    # @example 逆順での計算
    #   JapaneseBusinessDays.business_days_between(Date.new(2024, 1, 10), Date.new(2024, 1, 1))
    #   # => -6
    # @example 同じ日付
    #   JapaneseBusinessDays.business_days_between(Date.new(2024, 1, 1), Date.new(2024, 1, 1))
    #   # => 0
    # @since 0.1.0
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

    # 指定した日付が営業日かどうかを判定します
    #
    # 平日かつ日本の祝日でない場合にtrueを返します。カスタム設定された
    # 非営業日は営業日ではなく、カスタム営業日は祝日でも営業日として扱われます。
    #
    # @param date [Date, Time, DateTime, String] 判定する日付
    # @return [Boolean] 営業日の場合true、非営業日の場合false
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型の場合
    # @raise [InvalidDateError] 日付形式が無効な場合
    # @example 平日の判定
    #   JapaneseBusinessDays.business_day?(Date.new(2024, 1, 9))  # 火曜日
    #   # => true
    # @example 祝日の判定
    #   JapaneseBusinessDays.business_day?(Date.new(2024, 1, 1))  # 元日
    #   # => false
    # @example 土日の判定
    #   JapaneseBusinessDays.business_day?(Date.new(2024, 1, 6))  # 土曜日
    #   # => false
    # @example 文字列での日付指定
    #   JapaneseBusinessDays.business_day?('2024-01-09')
    #   # => true
    # @since 0.1.0
    def business_day?(date)
      validate_not_nil!(date, "date")
      normalized_date = normalize_date(date)
      business_day_calculator.business_day?(normalized_date)
    end

    # 指定した日付が日本の祝日かどうかを判定します
    #
    # 日本の法律で定められた祝日（固定祝日、移動祝日、ハッピーマンデー祝日、振替休日）
    # かどうかを判定します。カスタム設定された祝日も含まれます。
    #
    # @param date [Date, Time, DateTime, String] 判定する日付
    # @return [Boolean] 祝日の場合true、祝日でない場合false
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型の場合
    # @raise [InvalidDateError] 日付形式が無効な場合
    # @example 固定祝日の判定
    #   JapaneseBusinessDays.holiday?(Date.new(2024, 1, 1))  # 元日
    #   # => true
    # @example 移動祝日の判定
    #   JapaneseBusinessDays.holiday?(Date.new(2024, 3, 20))  # 春分の日
    #   # => true
    # @example ハッピーマンデー祝日の判定
    #   JapaneseBusinessDays.holiday?(Date.new(2024, 1, 8))   # 成人の日（第2月曜日）
    #   # => true
    # @example 振替休日の判定
    #   # 祝日が日曜日の場合、翌月曜日が振替休日
    #   JapaneseBusinessDays.holiday?(Date.new(2024, 2, 12))  # 建国記念の日の振替休日
    #   # => true (2024年の建国記念の日は日曜日のため)
    # @example 平日の判定
    #   JapaneseBusinessDays.holiday?(Date.new(2024, 1, 9))   # 火曜日
    #   # => false
    # @since 0.1.0
    def holiday?(date)
      validate_not_nil!(date, "date")
      normalized_date = normalize_date(date)
      holiday_calculator.holiday?(normalized_date)
    end

    # 指定した年の全祝日を取得します
    #
    # 指定した年の日本の祝日（固定祝日、移動祝日、ハッピーマンデー祝日、振替休日）
    # をすべて取得し、日付順にソートして返します。
    #
    # @param year [Integer] 対象年（1000-9999の範囲）
    # @return [Array<Holiday>] その年の祝日リスト（日付順）
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型・範囲の場合
    # @example 2024年の祝日を取得
    #   holidays = JapaneseBusinessDays.holidays_in_year(2024)
    #   holidays.each { |h| puts "#{h.date}: #{h.name} (#{h.type})" }
    #   # => 2024-01-01: 元日 (fixed)
    #   #    2024-01-08: 成人の日 (happy_monday)
    #   #    2024-02-11: 建国記念の日 (fixed)
    #   #    ...
    # @example 祝日の種類による分類
    #   holidays = JapaneseBusinessDays.holidays_in_year(2024)
    #   fixed_holidays = holidays.select { |h| h.type == :fixed }
    #   calculated_holidays = holidays.select { |h| h.type == :calculated }
    # @since 0.1.0
    def holidays_in_year(year)
      validate_not_nil!(year, "year")
      validate_year!(year)
      holiday_calculator.holidays_in_year(year)
    end

    # 指定した日付に営業日を加算します
    #
    # 基準日から指定した営業日数だけ先の営業日を計算します。
    # 土日、祝日、カスタム非営業日はスキップされます。
    #
    # @param date [Date, Time, DateTime, String] 基準日
    # @param days [Integer] 加算する営業日数（負の値の場合は減算）
    # @return [Date] 計算結果の日付
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型の場合
    # @raise [InvalidDateError] 日付形式が無効な場合
    # @example 基本的な加算
    #   JapaneseBusinessDays.add_business_days(Date.new(2024, 1, 5), 3)
    #   # => Date.new(2024, 1, 10) (1/6-1/8は土日月のためスキップ)
    # @example 祝日をまたぐ加算
    #   JapaneseBusinessDays.add_business_days(Date.new(2023, 12, 28), 3)
    #   # => Date.new(2024, 1, 4) (12/29-1/3は年末年始休暇)
    # @example 0日加算（営業日正規化）
    #   JapaneseBusinessDays.add_business_days(Date.new(2024, 1, 6), 0)  # 土曜日
    #   # => Date.new(2024, 1, 9) (次の営業日)
    # @example 負の値での減算
    #   JapaneseBusinessDays.add_business_days(Date.new(2024, 1, 10), -3)
    #   # => Date.new(2024, 1, 5)
    # @since 0.1.0
    def add_business_days(date, days)
      validate_not_nil!(date, "date")
      validate_not_nil!(days, "days")
      validate_integer!(days, "days")
      
      normalized_date = normalize_date(date)
      result = business_day_calculator.add_business_days(normalized_date, days)
      normalize_date(result)
    end

    # 指定した日付から営業日を減算します
    #
    # 基準日から指定した営業日数だけ前の営業日を計算します。
    # 土日、祝日、カスタム非営業日はスキップされます。
    #
    # @param date [Date, Time, DateTime, String] 基準日
    # @param days [Integer] 減算する営業日数（負の値の場合は加算）
    # @return [Date] 計算結果の日付
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型の場合
    # @raise [InvalidDateError] 日付形式が無効な場合
    # @example 基本的な減算
    #   JapaneseBusinessDays.subtract_business_days(Date.new(2024, 1, 10), 3)
    #   # => Date.new(2024, 1, 5)
    # @example 祝日をまたぐ減算
    #   JapaneseBusinessDays.subtract_business_days(Date.new(2024, 1, 4), 3)
    #   # => Date.new(2023, 12, 28) (12/29-1/3は年末年始休暇)
    # @example 0日減算（営業日正規化）
    #   JapaneseBusinessDays.subtract_business_days(Date.new(2024, 1, 6), 0)  # 土曜日
    #   # => Date.new(2024, 1, 9) (次の営業日)
    # @example 負の値での加算
    #   JapaneseBusinessDays.subtract_business_days(Date.new(2024, 1, 5), -3)
    #   # => Date.new(2024, 1, 10)
    # @since 0.1.0
    def subtract_business_days(date, days)
      validate_not_nil!(date, "date")
      validate_not_nil!(days, "days")
      validate_integer!(days, "days")
      
      normalized_date = normalize_date(date)
      result = business_day_calculator.subtract_business_days(normalized_date, days)
      normalize_date(result)
    end

    # 指定した日付の次の営業日を取得します
    #
    # 基準日の翌日以降で最初の営業日を返します。
    # 基準日が営業日であっても、翌日以降の営業日を返します。
    #
    # @param date [Date, Time, DateTime, String] 基準日
    # @return [Date] 次の営業日
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型の場合
    # @raise [InvalidDateError] 日付形式が無効な場合
    # @example 平日から次の営業日
    #   JapaneseBusinessDays.next_business_day(Date.new(2024, 1, 9))  # 火曜日
    #   # => Date.new(2024, 1, 10) (水曜日)
    # @example 金曜日から次の営業日
    #   JapaneseBusinessDays.next_business_day(Date.new(2024, 1, 5))  # 金曜日
    #   # => Date.new(2024, 1, 9) (月曜日、土日をスキップ)
    # @example 祝日前から次の営業日
    #   JapaneseBusinessDays.next_business_day(Date.new(2023, 12, 28)) # 木曜日
    #   # => Date.new(2024, 1, 4) (年末年始をスキップ)
    # @since 0.1.0
    def next_business_day(date)
      validate_not_nil!(date, "date")
      normalized_date = normalize_date(date)
      result = business_day_calculator.next_business_day(normalized_date)
      normalize_date(result)
    end

    # 指定した日付の前の営業日を取得します
    #
    # 基準日の前日以前で最初の営業日を返します。
    # 基準日が営業日であっても、前日以前の営業日を返します。
    #
    # @param date [Date, Time, DateTime, String] 基準日
    # @return [Date] 前の営業日
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型の場合
    # @raise [InvalidDateError] 日付形式が無効な場合
    # @example 平日から前の営業日
    #   JapaneseBusinessDays.previous_business_day(Date.new(2024, 1, 10)) # 水曜日
    #   # => Date.new(2024, 1, 9) (火曜日)
    # @example 月曜日から前の営業日
    #   JapaneseBusinessDays.previous_business_day(Date.new(2024, 1, 9))  # 月曜日
    #   # => Date.new(2024, 1, 5) (金曜日、土日をスキップ)
    # @example 祝日後から前の営業日
    #   JapaneseBusinessDays.previous_business_day(Date.new(2024, 1, 4))  # 木曜日
    #   # => Date.new(2023, 12, 28) (年末年始をスキップ)
    # @since 0.1.0
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
