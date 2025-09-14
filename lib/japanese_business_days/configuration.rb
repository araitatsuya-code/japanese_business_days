# frozen_string_literal: true

module JapaneseBusinessDays
  # カスタムビジネスルールの設定を管理するクラス
  #
  # このクラスは、標準の日本の祝日・週末設定に加えて、
  # 組織固有のカスタムルールを設定するために使用されます。
  # カスタム祝日の追加、特定祝日の営業日化、週末定義の変更などが可能です。
  #
  # @example 基本的な設定
  #   config = JapaneseBusinessDays::Configuration.new
  #   config.add_holiday(Date.new(2024, 12, 31))  # 大晦日を祝日に
  #   config.add_business_day(Date.new(2024, 1, 1))  # 元日を営業日に
  #   config.weekend_days = [6]  # 土曜日のみを週末に
  #
  # @example JapaneseBusinessDays.configureブロックでの使用
  #   JapaneseBusinessDays.configure do |config|
  #     config.additional_holidays = [Date.new(2024, 12, 30), Date.new(2024, 12, 31)]
  #     config.weekend_days = [0, 6]  # 日曜日と土曜日
  #   end
  #
  # @author JapaneseBusinessDays Team
  # @since 0.1.0
  class Configuration
    attr_reader :additional_holidays, :additional_business_days, :weekend_days

    # 有効な曜日（0=日曜日, 6=土曜日）
    VALID_WEEKDAYS = (0..6).freeze

    def initialize
      @additional_holidays = []
      @additional_business_days = []
      @weekend_days = [0, 6] # 日曜日、土曜日
    end

    # 追加祝日を一括設定します
    #
    # 標準の日本の祝日に加えて、組織固有の祝日を設定します。
    # 既存の追加祝日は上書きされます。
    #
    # @param holidays [Array<Date>] 追加する祝日の配列
    # @raise [InvalidArgumentError] 無効な配列または日付オブジェクトの場合
    # @example 年末年始の特別休暇を設定
    #   config.additional_holidays = [
    #     Date.new(2024, 12, 30),
    #     Date.new(2024, 12, 31)
    #   ]
    # @since 0.1.0
    def additional_holidays=(holidays)
      validate_date_array!(holidays, "additional_holidays")
      @additional_holidays = holidays.dup
    end

    # 追加営業日を一括設定します
    #
    # 通常は祝日や週末である日を営業日として扱うよう設定します。
    # 既存の追加営業日は上書きされます。
    #
    # @param business_days [Array<Date>] 追加する営業日の配列
    # @raise [InvalidArgumentError] 無効な配列または日付オブジェクトの場合
    # @example 特定の祝日を営業日として扱う
    #   config.additional_business_days = [
    #     Date.new(2024, 1, 1),   # 元日を営業日に
    #     Date.new(2024, 5, 3)    # 憲法記念日を営業日に
    #   ]
    # @since 0.1.0
    def additional_business_days=(business_days)
      validate_date_array!(business_days, "additional_business_days")
      @additional_business_days = business_days.dup
    end

    # 週末曜日を設定します
    #
    # 週末として扱う曜日を設定します。デフォルトは[0, 6]（日曜日と土曜日）です。
    # 0=日曜日、1=月曜日、...、6=土曜日として指定します。
    #
    # @param days [Array<Integer>] 週末とする曜日の配列（0-6の整数）
    # @raise [InvalidArgumentError] 無効な配列、重複、または範囲外の値の場合
    # @example 土曜日のみを週末に設定
    #   config.weekend_days = [6]
    # @example 金曜日と土曜日を週末に設定（中東スタイル）
    #   config.weekend_days = [5, 6]
    # @example 日曜日のみを週末に設定
    #   config.weekend_days = [0]
    # @since 0.1.0
    def weekend_days=(days)
      validate_weekend_days!(days)
      @weekend_days = days.dup
    end

    # カスタム祝日を追加します
    #
    # 既存の追加祝日リストに新しい祝日を追加します。
    # 重複する日付は自動的に除外されます。
    #
    # @param date [Date, Time, DateTime, String] 追加する祝日
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型の場合
    # @raise [InvalidDateError] 日付形式が無効な場合
    # @example 個別に祝日を追加
    #   config.add_holiday(Date.new(2024, 12, 31))
    #   config.add_holiday('2024-12-30')
    # @example 既に追加済みの日付は重複しない
    #   config.add_holiday(Date.new(2024, 12, 31))
    #   config.add_holiday(Date.new(2024, 12, 31))  # 重複は無視される
    # @since 0.1.0
    def add_holiday(date)
      validate_not_nil!(date, "date")
      normalized_date = normalize_date(date)
      unless @additional_holidays.include?(normalized_date)
        @additional_holidays << normalized_date
      end
    end

    # カスタム営業日を追加します（祝日の上書き）
    #
    # 通常は祝日や週末である日を営業日として扱うよう追加します。
    # 重複する日付は自動的に除外されます。
    #
    # @param date [Date, Time, DateTime, String] 追加する営業日
    # @raise [InvalidArgumentError] 引数がnilまたは無効な型の場合
    # @raise [InvalidDateError] 日付形式が無効な場合
    # @example 祝日を営業日として扱う
    #   config.add_business_day(Date.new(2024, 1, 1))  # 元日を営業日に
    # @example 土曜日を営業日として扱う
    #   config.add_business_day(Date.new(2024, 1, 6))  # 土曜日を営業日に
    # @since 0.1.0
    def add_business_day(date)
      validate_not_nil!(date, "date")
      normalized_date = normalize_date(date)
      unless @additional_business_days.include?(normalized_date)
        @additional_business_days << normalized_date
      end
    end

    # 指定した日付がカスタム祝日かどうかを判定します
    #
    # @param date [Date] 判定する日付
    # @return [Boolean] カスタム祝日の場合true、そうでなければfalse
    # @example カスタム祝日の判定
    #   config.add_holiday(Date.new(2024, 12, 31))
    #   config.additional_holiday?(Date.new(2024, 12, 31))  # => true
    #   config.additional_holiday?(Date.new(2024, 12, 30))  # => false
    # @since 0.1.0
    def additional_holiday?(date)
      @additional_holidays.include?(date)
    end

    # 指定した日付がカスタム営業日かどうかを判定します
    #
    # @param date [Date] 判定する日付
    # @return [Boolean] カスタム営業日の場合true、そうでなければfalse
    # @example カスタム営業日の判定
    #   config.add_business_day(Date.new(2024, 1, 1))  # 元日を営業日に
    #   config.additional_business_day?(Date.new(2024, 1, 1))  # => true
    #   config.additional_business_day?(Date.new(2024, 1, 2))  # => false
    # @since 0.1.0
    def additional_business_day?(date)
      @additional_business_days.include?(date)
    end

    # 指定した曜日が週末かどうかを判定します
    #
    # @param wday [Integer] 曜日（0=日曜日, 1=月曜日, ..., 6=土曜日）
    # @return [Boolean] 週末の場合true、そうでなければfalse
    # @example 標準設定での週末判定
    #   config.weekend_day?(0)  # 日曜日 => true
    #   config.weekend_day?(1)  # 月曜日 => false
    #   config.weekend_day?(6)  # 土曜日 => true
    # @example カスタム設定での週末判定
    #   config.weekend_days = [5, 6]  # 金土を週末に
    #   config.weekend_day?(5)  # 金曜日 => true
    #   config.weekend_day?(0)  # 日曜日 => false
    # @since 0.1.0
    def weekend_day?(wday)
      @weekend_days.include?(wday)
    end

    # 設定をデフォルト値にリセットします
    #
    # すべてのカスタム設定をクリアし、デフォルト値に戻します。
    # - additional_holidays: 空配列
    # - additional_business_days: 空配列  
    # - weekend_days: [0, 6] (日曜日と土曜日)
    #
    # @example 設定のリセット
    #   config.add_holiday(Date.new(2024, 12, 31))
    #   config.weekend_days = [6]
    #   config.reset!
    #   config.additional_holidays     # => []
    #   config.weekend_days           # => [0, 6]
    # @since 0.1.0
    def reset!
      @additional_holidays.clear
      @additional_business_days.clear
      @weekend_days = [0, 6]
    end

    private

    # 日付正規化
    # @param date [Date, Time, DateTime, String] 正規化する日付
    # @return [Date] 正規化された日付
    # @raise [InvalidDateError] 無効な日付形式の場合
    # @raise [InvalidArgumentError] 無効な引数タイプの場合
    def normalize_date(date)
      case date
      when Date
        date
      when Time, DateTime
        date.to_date
      when String
        validate_date_string!(date)
        Date.parse(date)
      else
        raise InvalidArgumentError, "Invalid date type: #{date.class}. Expected Date, Time, DateTime, or String"
      end
    rescue ArgumentError => e
      raise InvalidDateError, "Invalid date format: #{date} - #{e.message}"
    end

    # nil値の検証
    # @param value [Object] 検証する値
    # @param param_name [String] パラメータ名
    # @raise [InvalidArgumentError] 値がnilの場合
    def validate_not_nil!(value, param_name)
      if value.nil?
        raise InvalidArgumentError, "#{param_name} cannot be nil"
      end
    end

    # 日付文字列の検証
    # @param date_string [String] 検証する日付文字列
    # @raise [InvalidArgumentError] 空文字列の場合
    def validate_date_string!(date_string)
      if date_string.empty?
        raise InvalidArgumentError, "Date string cannot be empty"
      end
      
      if date_string.strip.empty?
        raise InvalidArgumentError, "Date string cannot be blank"
      end
    end

    # 日付配列の検証
    # @param dates [Array] 検証する日付配列
    # @param field_name [String] フィールド名（エラーメッセージ用）
    # @raise [InvalidArgumentError] 無効な日付配列の場合
    def validate_date_array!(dates, field_name)
      unless dates.is_a?(Array)
        raise InvalidArgumentError, "#{field_name} must be an Array, got #{dates.class}"
      end

      dates.each_with_index do |date, index|
        unless date.is_a?(Date)
          raise InvalidArgumentError, 
            "#{field_name}[#{index}] must be a Date object, got #{date.class}"
        end
      end
    end

    # 週末曜日の検証
    # @param days [Array<Integer>] 検証する曜日配列
    # @raise [InvalidArgumentError] 無効な曜日配列の場合
    def validate_weekend_days!(days)
      unless days.is_a?(Array)
        raise InvalidArgumentError, "weekend_days must be an Array, got #{days.class}"
      end

      if days.empty?
        raise InvalidArgumentError, "weekend_days cannot be empty"
      end

      days.each_with_index do |day, index|
        unless day.is_a?(Integer) && VALID_WEEKDAYS.include?(day)
          raise InvalidArgumentError, 
            "weekend_days[#{index}] must be an integer between 0-6, got #{day.inspect}"
        end
      end

      if days.uniq.length != days.length
        raise InvalidArgumentError, "weekend_days cannot contain duplicate values"
      end
    end
  end
end