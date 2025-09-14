# frozen_string_literal: true

module JapaneseBusinessDays
  # Date/Time/DateTimeクラスの拡張メソッドを提供するモジュール
  #
  # このモジュールは、Ruby標準のDate、Time、DateTimeクラス、
  # およびRailsのActiveSupport::TimeWithZoneクラスに営業日計算メソッドを追加します。
  # Railsアプリケーションでは自動的に拡張が適用されます。
  #
  # @example Date拡張の使用
  #   date = Date.new(2024, 1, 5)
  #   date.business_day?           # => true
  #   date.add_business_days(3)    # => Date.new(2024, 1, 10)
  #   date.next_business_day       # => Date.new(2024, 1, 9)
  #
  # @example Time拡張の使用
  #   time = Time.new(2024, 1, 5, 14, 30, 0)
  #   time.business_day?           # => true
  #   next_time = time.add_business_days(1)  # 時刻情報を保持
  #   # => Time.new(2024, 1, 9, 14, 30, 0)
  #
  # @example Rails環境での自動拡張
  #   # Railsが検出されると自動的に拡張が適用される
  #   Date.today.business_day?
  #   1.week.from_now.add_business_days(5)
  #
  # @author JapaneseBusinessDays Team
  # @since 0.1.0
  module DateExtensions
    # 営業日を加算します
    #
    # 現在の日付に指定した営業日数を加算し、元のオブジェクトと同じ型で結果を返します。
    # Time/DateTimeオブジェクトの場合、時刻情報は保持されます。
    #
    # @param days [Integer] 加算する営業日数（負の値の場合は減算）
    # @return [Date, Time, DateTime, ActiveSupport::TimeWithZone] 計算結果（元のオブジェクトと同じ型）
    # @raise [InvalidArgumentError] 無効な引数の場合
    # @example Dateオブジェクトでの使用
    #   Date.new(2024, 1, 5).add_business_days(3)
    #   # => Date.new(2024, 1, 10)
    # @example Timeオブジェクトでの使用（時刻保持）
    #   Time.new(2024, 1, 5, 14, 30).add_business_days(1)
    #   # => Time.new(2024, 1, 9, 14, 30) (時刻情報が保持される)
    # @example 負の値での減算
    #   Date.new(2024, 1, 10).add_business_days(-3)
    #   # => Date.new(2024, 1, 5)
    # @since 0.1.0
    def add_business_days(days)
      validate_days_parameter!(days)
      date = normalize_to_date
      result_date = JapaneseBusinessDays.send(:business_day_calculator).add_business_days(date, days)
      convert_result_to_original_type(result_date)
    end

    # 営業日を減算します
    #
    # 現在の日付から指定した営業日数を減算し、元のオブジェクトと同じ型で結果を返します。
    # Time/DateTimeオブジェクトの場合、時刻情報は保持されます。
    #
    # @param days [Integer] 減算する営業日数（負の値の場合は加算）
    # @return [Date, Time, DateTime, ActiveSupport::TimeWithZone] 計算結果（元のオブジェクトと同じ型）
    # @raise [InvalidArgumentError] 無効な引数の場合
    # @example Dateオブジェクトでの使用
    #   Date.new(2024, 1, 10).subtract_business_days(3)
    #   # => Date.new(2024, 1, 5)
    # @example Timeオブジェクトでの使用（時刻保持）
    #   Time.new(2024, 1, 10, 9, 0).subtract_business_days(2)
    #   # => Time.new(2024, 1, 8, 9, 0) (時刻情報が保持される)
    # @example 負の値での加算
    #   Date.new(2024, 1, 5).subtract_business_days(-3)
    #   # => Date.new(2024, 1, 10)
    # @since 0.1.0
    def subtract_business_days(days)
      validate_days_parameter!(days)
      date = normalize_to_date
      result_date = JapaneseBusinessDays.send(:business_day_calculator).subtract_business_days(date, days)
      convert_result_to_original_type(result_date)
    end

    # 営業日かどうかを判定します
    #
    # 現在の日付が営業日（平日かつ祝日でない）かどうかを判定します。
    # カスタム設定された非営業日・営業日も考慮されます。
    #
    # @return [Boolean] 営業日の場合true、非営業日の場合false
    # @example 平日の判定
    #   Date.new(2024, 1, 9).business_day?  # 火曜日
    #   # => true
    # @example 祝日の判定
    #   Date.new(2024, 1, 1).business_day?  # 元日
    #   # => false
    # @example 土日の判定
    #   Date.new(2024, 1, 6).business_day?  # 土曜日
    #   # => false
    # @since 0.1.0
    def business_day?
      date = normalize_to_date
      JapaneseBusinessDays.send(:business_day_calculator).business_day?(date)
    end

    # 祝日かどうかを判定します
    #
    # 現在の日付が日本の祝日（固定祝日、移動祝日、ハッピーマンデー祝日、振替休日）
    # かどうかを判定します。カスタム設定された祝日も含まれます。
    #
    # @return [Boolean] 祝日の場合true、祝日でない場合false
    # @example 固定祝日の判定
    #   Date.new(2024, 1, 1).holiday?  # 元日
    #   # => true
    # @example ハッピーマンデー祝日の判定
    #   Date.new(2024, 1, 8).holiday?  # 成人の日
    #   # => true
    # @example 平日の判定
    #   Date.new(2024, 1, 9).holiday?  # 火曜日
    #   # => false
    # @since 0.1.0
    def holiday?
      date = normalize_to_date
      JapaneseBusinessDays.send(:holiday_calculator).holiday?(date)
    end

    # 次の営業日を取得します
    #
    # 現在の日付の翌日以降で最初の営業日を返します。
    # 元のオブジェクトと同じ型で結果を返し、Time/DateTimeの場合は時刻情報を保持します。
    #
    # @return [Date, Time, DateTime, ActiveSupport::TimeWithZone] 次の営業日（元のオブジェクトと同じ型）
    # @example 平日から次の営業日
    #   Date.new(2024, 1, 9).next_business_day  # 火曜日
    #   # => Date.new(2024, 1, 10) (水曜日)
    # @example 金曜日から次の営業日
    #   Date.new(2024, 1, 5).next_business_day  # 金曜日
    #   # => Date.new(2024, 1, 9) (月曜日、土日をスキップ)
    # @example Timeオブジェクトでの使用
    #   Time.new(2024, 1, 5, 17, 0).next_business_day
    #   # => Time.new(2024, 1, 9, 17, 0) (時刻情報が保持される)
    # @since 0.1.0
    def next_business_day
      date = normalize_to_date
      result_date = JapaneseBusinessDays.send(:business_day_calculator).next_business_day(date)
      convert_result_to_original_type(result_date)
    end

    # 前の営業日を取得します
    #
    # 現在の日付の前日以前で最初の営業日を返します。
    # 元のオブジェクトと同じ型で結果を返し、Time/DateTimeの場合は時刻情報を保持します。
    #
    # @return [Date, Time, DateTime, ActiveSupport::TimeWithZone] 前の営業日（元のオブジェクトと同じ型）
    # @example 平日から前の営業日
    #   Date.new(2024, 1, 10).previous_business_day  # 水曜日
    #   # => Date.new(2024, 1, 9) (火曜日)
    # @example 月曜日から前の営業日
    #   Date.new(2024, 1, 9).previous_business_day   # 月曜日
    #   # => Date.new(2024, 1, 5) (金曜日、土日をスキップ)
    # @example Timeオブジェクトでの使用
    #   Time.new(2024, 1, 9, 9, 0).previous_business_day
    #   # => Time.new(2024, 1, 5, 9, 0) (時刻情報が保持される)
    # @since 0.1.0
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