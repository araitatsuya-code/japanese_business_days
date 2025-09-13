# frozen_string_literal: true

module JapaneseBusinessDays
  # カスタムルールの設定を管理するクラス
  class Configuration
    attr_reader :additional_holidays, :additional_business_days, :weekend_days

    # 有効な曜日（0=日曜日, 6=土曜日）
    VALID_WEEKDAYS = (0..6).freeze

    def initialize
      @additional_holidays = []
      @additional_business_days = []
      @weekend_days = [0, 6] # 日曜日、土曜日
    end

    # 追加祝日の設定
    # @param holidays [Array<Date>] 追加する祝日の配列
    def additional_holidays=(holidays)
      validate_date_array!(holidays, "additional_holidays")
      @additional_holidays = holidays.dup
    end

    # 追加営業日の設定
    # @param business_days [Array<Date>] 追加する営業日の配列
    def additional_business_days=(business_days)
      validate_date_array!(business_days, "additional_business_days")
      @additional_business_days = business_days.dup
    end

    # 週末曜日の設定
    # @param days [Array<Integer>] 週末とする曜日の配列
    def weekend_days=(days)
      validate_weekend_days!(days)
      @weekend_days = days.dup
    end

    # カスタム祝日追加
    # @param date [Date, Time, DateTime, String] 追加する祝日
    def add_holiday(date)
      normalized_date = normalize_date(date)
      unless @additional_holidays.include?(normalized_date)
        @additional_holidays << normalized_date
      end
    end

    # カスタム営業日追加（祝日の上書き）
    # @param date [Date, Time, DateTime, String] 追加する営業日
    def add_business_day(date)
      normalized_date = normalize_date(date)
      unless @additional_business_days.include?(normalized_date)
        @additional_business_days << normalized_date
      end
    end

    # 指定した日付がカスタム祝日かどうかを判定
    # @param date [Date] 判定する日付
    # @return [Boolean] カスタム祝日の場合true
    def additional_holiday?(date)
      @additional_holidays.include?(date)
    end

    # 指定した日付がカスタム営業日かどうかを判定
    # @param date [Date] 判定する日付
    # @return [Boolean] カスタム営業日の場合true
    def additional_business_day?(date)
      @additional_business_days.include?(date)
    end

    # 指定した曜日が週末かどうかを判定
    # @param wday [Integer] 曜日（0=日曜日, 6=土曜日）
    # @return [Boolean] 週末の場合true
    def weekend_day?(wday)
      @weekend_days.include?(wday)
    end

    # 設定をリセット（デフォルト値に戻す）
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
        Date.parse(date)
      else
        raise InvalidArgumentError, "Invalid date type: #{date.class}"
      end
    rescue ArgumentError => e
      raise InvalidDateError, "Invalid date format: #{date} - #{e.message}"
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