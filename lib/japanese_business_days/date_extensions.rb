# frozen_string_literal: true

module JapaneseBusinessDays
  # Date/Timeクラスの拡張を提供するモジュール
  module DateExtensions
    # 営業日加算
    # @param days [Integer] 加算する営業日数
    # @return [Date, Time, DateTime] 計算結果の日付（元のオブジェクトと同じ型）
    # @raise [InvalidArgumentError] 無効な引数の場合
    def add_business_days(days)
      validate_days_parameter!(days)
      date = normalize_to_date
      result_date = JapaneseBusinessDays.send(:business_day_calculator).add_business_days(date, days)
      convert_result_to_original_type(result_date)
    end

    # 営業日減算
    # @param days [Integer] 減算する営業日数
    # @return [Date, Time, DateTime] 計算結果の日付（元のオブジェクトと同じ型）
    # @raise [InvalidArgumentError] 無効な引数の場合
    def subtract_business_days(days)
      validate_days_parameter!(days)
      date = normalize_to_date
      result_date = JapaneseBusinessDays.send(:business_day_calculator).subtract_business_days(date, days)
      convert_result_to_original_type(result_date)
    end

    # 営業日判定
    # @return [Boolean] 営業日の場合true
    def business_day?
      date = normalize_to_date
      JapaneseBusinessDays.send(:business_day_calculator).business_day?(date)
    end

    # 祝日判定
    # @return [Boolean] 祝日の場合true
    def holiday?
      date = normalize_to_date
      JapaneseBusinessDays.send(:holiday_calculator).holiday?(date)
    end

    # 次の営業日
    # @return [Date, Time, DateTime] 次の営業日（元のオブジェクトと同じ型）
    def next_business_day
      date = normalize_to_date
      result_date = JapaneseBusinessDays.send(:business_day_calculator).next_business_day(date)
      convert_result_to_original_type(result_date)
    end

    # 前の営業日
    # @return [Date, Time, DateTime] 前の営業日（元のオブジェクトと同じ型）
    def previous_business_day
      date = normalize_to_date
      result_date = JapaneseBusinessDays.send(:business_day_calculator).previous_business_day(date)
      convert_result_to_original_type(result_date)
    end

    private

    # 自身をDateオブジェクトに正規化
    # @return [Date] 正規化された日付
    # @raise [InvalidArgumentError] サポートされていない日付型の場合
    def normalize_to_date
      case self
      when Date
        self
      when Time, DateTime
        to_date
      else
        # ActiveSupport::TimeWithZoneの場合も考慮
        if defined?(ActiveSupport::TimeWithZone) && is_a?(ActiveSupport::TimeWithZone)
          to_date
        else
          raise InvalidArgumentError, "Unsupported date type: #{self.class}"
        end
      end
    end

    # 日数パラメータの検証
    # @param days [Object] 検証する日数
    # @raise [InvalidArgumentError] 無効な日数の場合
    def validate_days_parameter!(days)
      if days.nil?
        raise InvalidArgumentError, "days cannot be nil"
      end
      
      unless days.is_a?(Integer)
        raise InvalidArgumentError, "days must be an Integer, got #{days.class}"
      end
    end

    # 結果を元のオブジェクトの型に変換
    # @param result_date [Date] 計算結果の日付
    # @return [Date, Time, DateTime, ActiveSupport::TimeWithZone] 元のオブジェクトと同じ型の結果
    def convert_result_to_original_type(result_date)
      case self
      when Date
        result_date
      when Time
        # Timeオブジェクトの場合、元の時刻情報を保持して新しい日付に設定
        Time.new(result_date.year, result_date.month, result_date.day, hour, min, sec, utc_offset)
      when DateTime
        # DateTimeオブジェクトの場合、元の時刻情報を保持して新しい日付に設定
        DateTime.new(result_date.year, result_date.month, result_date.day, hour, min, sec, offset)
      else
        # ActiveSupport::TimeWithZoneの場合
        if defined?(ActiveSupport::TimeWithZone) && is_a?(ActiveSupport::TimeWithZone)
          # 元のタイムゾーンを保持して新しい日付に設定
          time_zone.local(result_date.year, result_date.month, result_date.day, hour, min, sec)
        else
          result_date
        end
      end
    end
  end
end