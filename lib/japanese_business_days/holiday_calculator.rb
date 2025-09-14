# frozen_string_literal: true

require "date"

module JapaneseBusinessDays
  # 日本の祝日計算を担当するクラス
  class HolidayCalculator
    # 固定祝日の定義 [月, 日] => 祝日名
    FIXED_HOLIDAYS = {
      [1, 1] => "元日",
      [2, 11] => "建国記念の日",
      [4, 29] => "昭和の日",
      [5, 3] => "憲法記念日",
      [5, 4] => "みどりの日",
      [5, 5] => "こどもの日",
      [8, 11] => "山の日",
      [11, 3] => "文化の日",
      [11, 23] => "勤労感謝の日",
      [12, 23] => "天皇誕生日"
    }.freeze

    # ハッピーマンデー祝日の定義 [月, 第n週] => 祝日名
    HAPPY_MONDAY_HOLIDAYS = {
      [1, 2] => "成人の日",      # 1月第2月曜日
      [7, 3] => "海の日",       # 7月第3月曜日
      [9, 3] => "敬老の日", # 9月第3月曜日
      [10, 2] => "スポーツの日" # 10月第2月曜日
    }.freeze

    def initialize
      # 将来的にキャッシュマネージャーやカスタム設定を受け取る可能性がある
    end

    # 指定した日付が祝日かどうかを判定する
    # @param date [Date] 判定する日付
    # @return [Boolean] 祝日の場合true
    # @raise [InvalidArgumentError] 無効な引数の場合
    def holiday?(date)
      normalized_date = normalize_date(date)

      # 固定祝日チェック
      return true if fixed_holiday?(normalized_date)

      # 計算祝日チェック（春分の日・秋分の日）
      return true if calculated_holiday?(normalized_date)

      # ハッピーマンデー祝日チェック
      return true if happy_monday_holiday?(normalized_date)

      # 振替休日チェック
      return true if substitute_holiday?(normalized_date)

      false
    rescue StandardError => e
      handle_calculation_error(e, "holiday calculation for #{date}")
    end

    # 指定した年の全祝日を取得する
    # @param year [Integer] 年
    # @return [Array<Holiday>] その年の祝日一覧
    # @raise [InvalidArgumentError] 無効な年の場合
    def holidays_in_year(year)
      validate_year!(year)

      holidays = []
      holidays.concat(fixed_holidays_in_year(year))
      holidays.concat(calculated_holidays_in_year(year))
      holidays.concat(happy_monday_holidays_in_year(year))
      holidays.concat(substitute_holidays_in_year(year, holidays))

      holidays.sort_by(&:date)
    rescue StandardError => e
      handle_calculation_error(e, "holiday calculation for year #{year}")
    end

    # 振替休日かどうかを判定する
    # @param date [Date] 判定する日付
    # @return [Boolean] 振替休日の場合true
    def substitute_holiday?(date)
      normalized_date = normalize_date(date)

      # 月曜日でない場合は振替休日ではない
      return false unless normalized_date.monday?

      # 前日（日曜日）が祝日かチェック
      previous_day = normalized_date - 1
      return false unless previous_day.sunday?

      # 前日が祝日（振替休日以外）かチェック
      fixed_holiday?(previous_day) ||
        calculated_holiday?(previous_day) ||
        happy_monday_holiday?(previous_day)
    rescue StandardError => e
      handle_calculation_error(e, "substitute holiday calculation for #{date}")
    end

    private

    # 日付の正規化
    # @param date [Date, Time, DateTime, String] 正規化する日付
    # @return [Date] 正規化された日付
    # @raise [InvalidArgumentError] 無効な日付の場合
    def normalize_date(date)
      case date
      when Date
        date
      when Time, DateTime
        date.to_date
      when String
        begin
          Date.parse(date)
        rescue Date::Error => e
          raise InvalidArgumentError, "Invalid date string: #{date} (#{e.message})"
        end
      else
        raise InvalidArgumentError, "Date must be Date, Time, DateTime, or String, got #{date.class}"
      end
    end

    # 年の検証
    # @param year [Integer] 検証する年
    # @raise [InvalidArgumentError] 無効な年の場合
    def validate_year!(year)
      raise InvalidArgumentError, "Year must be an Integer, got #{year.class}" unless year.is_a?(Integer)

      return if (1000..9999).cover?(year)

      raise InvalidArgumentError, "Year must be between 1000 and 9999, got #{year}"
    end

    # 固定祝日かどうかを判定
    # @param date [Date] 判定する日付
    # @return [Boolean] 固定祝日の場合true
    def fixed_holiday?(date)
      FIXED_HOLIDAYS.key?([date.month, date.day])
    end

    # 計算祝日かどうかを判定（春分の日・秋分の日）
    # @param date [Date] 判定する日付
    # @return [Boolean] 計算祝日の場合true
    def calculated_holiday?(date)
      vernal_equinox = vernal_equinox_day(date.year)
      autumnal_equinox = autumnal_equinox_day(date.year)

      date == vernal_equinox || date == autumnal_equinox
    end

    # ハッピーマンデー祝日かどうかを判定
    # @param date [Date] 判定する日付
    # @return [Boolean] ハッピーマンデー祝日の場合true
    def happy_monday_holiday?(date)
      # 月曜日でない場合はハッピーマンデー祝日ではない
      return false unless date.monday?

      HAPPY_MONDAY_HOLIDAYS.each_key do |(month, nth_week)|
        if date.month == month
          nth_monday = nth_weekday(date.year, month, nth_week, 1) # 1 = Monday
          return true if date == nth_monday
        end
      end

      false
    end

    # 指定年の固定祝日を取得
    # @param year [Integer] 年
    # @return [Array<Holiday>] 固定祝日一覧
    def fixed_holidays_in_year(year)
      holidays = []

      FIXED_HOLIDAYS.each do |(month, day), name|
        date = Date.new(year, month, day)
        holidays << Holiday.new(date, name, :fixed)
      rescue Date::Error
        # 無効な日付（例：2月30日）はスキップ
        next
      end

      holidays
    end

    # 指定年の計算祝日を取得
    # @param year [Integer] 年
    # @return [Array<Holiday>] 計算祝日一覧
    def calculated_holidays_in_year(year)
      holidays = []

      vernal_equinox = vernal_equinox_day(year)
      autumnal_equinox = autumnal_equinox_day(year)

      holidays << Holiday.new(vernal_equinox, "春分の日", :calculated)
      holidays << Holiday.new(autumnal_equinox, "秋分の日", :calculated)

      holidays
    end

    # 指定年のハッピーマンデー祝日を取得
    # @param year [Integer] 年
    # @return [Array<Holiday>] ハッピーマンデー祝日一覧
    def happy_monday_holidays_in_year(year)
      holidays = []

      HAPPY_MONDAY_HOLIDAYS.each do |(month, nth_week), name|
        date = nth_weekday(year, month, nth_week, 1) # 1 = Monday
        holidays << Holiday.new(date, name, :happy_monday)
      end

      holidays
    end

    # 指定年の振替休日を取得
    # @param year [Integer] 年
    # @param existing_holidays [Array<Holiday>] 既存の祝日一覧
    # @return [Array<Holiday>] 振替休日一覧
    def substitute_holidays_in_year(_year, existing_holidays)
      substitute_holidays = []

      # 既存の祝日（振替休日以外）で日曜日のものを探す
      existing_holidays.each do |holiday|
        next if holiday.type == :substitute # 振替休日は除外

        next unless holiday.date.sunday?

        # 日曜日の祝日の翌日（月曜日）を振替休日とする
        substitute_date = holiday.date + 1

        # 振替休日が既存の祝日と重複しないかチェック
        substitute_holidays << Holiday.new(substitute_date, "振替休日", :substitute) unless existing_holidays.any? { |h| h.date == substitute_date }
      end

      substitute_holidays
    end

    # 春分の日を計算する
    # @param year [Integer] 年
    # @return [Date] 春分の日
    def vernal_equinox_day(year)
      # 春分の日の計算式（1851年〜2150年まで有効）
      # 参考: 国立天文台の計算式
      day = case year
            when 1851..1899
              19.8277
            when 1900..1979
              21.124
            when 1980..2099
              20.8431
            when 2100..2150
              21.851
            else
              # 範囲外の年は近似値を使用
              20.8431
            end

      # 年による補正
      correction = case year
                   when 1851..1899
                     (0.2422 * (year - 1851)) - ((year - 1851) / 4).floor
                   when 1900..1979
                     (0.2422 * (year - 1900)) - ((year - 1900) / 4).floor
                   when 1980..2099
                     (0.2422 * (year - 1980)) - ((year - 1980) / 4).floor
                   when 2100..2150
                     (0.2422 * (year - 2100)) - ((year - 2100) / 4).floor
                   else
                     (0.2422 * (year - 1980)) - ((year - 1980) / 4).floor
                   end

      calculated_day = (day + correction).floor
      Date.new(year, 3, calculated_day)
    end

    # 秋分の日を計算する
    # @param year [Integer] 年
    # @return [Date] 秋分の日
    def autumnal_equinox_day(year)
      # 秋分の日の計算式（1851年〜2150年まで有効）
      # 参考: 国立天文台の計算式
      day = case year
            when 1851..1899
              22.7020
            when 1900..1979
              23.73
            when 1980..2099
              23.2488
            when 2100..2150
              24.2488
            else
              # 範囲外の年は近似値を使用
              23.2488
            end

      # 年による補正
      correction = case year
                   when 1851..1899
                     (0.2422 * (year - 1851)) - ((year - 1851) / 4).floor
                   when 1900..1979
                     (0.2422 * (year - 1900)) - ((year - 1900) / 4).floor
                   when 1980..2099
                     (0.2422 * (year - 1980)) - ((year - 1980) / 4).floor
                   when 2100..2150
                     (0.2422 * (year - 2100)) - ((year - 2100) / 4).floor
                   else
                     (0.2422 * (year - 1980)) - ((year - 1980) / 4).floor
                   end

      calculated_day = (day + correction).floor
      Date.new(year, 9, calculated_day)
    end

    # 指定した月の第n週の指定曜日を取得する
    # @param year [Integer] 年
    # @param month [Integer] 月
    # @param nth [Integer] 第n週（1-5）
    # @param weekday [Integer] 曜日（0=日曜日, 1=月曜日, ..., 6=土曜日）
    # @return [Date] 該当する日付
    def nth_weekday(year, month, nth, weekday)
      # 月の最初の日を取得
      first_day = Date.new(year, month, 1)

      # 最初の日の曜日を取得（0=日曜日, 1=月曜日, ..., 6=土曜日）
      first_weekday = first_day.wday

      # 指定した曜日の最初の出現日を計算
      days_to_add = (weekday - first_weekday) % 7
      first_occurrence = first_day + days_to_add

      # 第n週の該当日を計算
      target_date = first_occurrence + ((nth - 1) * 7)

      # 月をまたがないかチェック
      if target_date.month != month
        raise ArgumentError,
              "The #{nth}#{ordinal_suffix(nth)} #{weekday_name(weekday)} of #{month}/#{year} does not exist"
      end

      target_date
    end

    # 序数詞のサフィックスを取得
    # @param n [Integer] 数値
    # @return [String] サフィックス
    def ordinal_suffix(n)
      case n
      when 1 then "st"
      when 2 then "nd"
      when 3 then "rd"
      else "th"
      end
    end

    # 曜日名を取得
    # @param weekday [Integer] 曜日（0-6）
    # @return [String] 曜日名
    def weekday_name(weekday)
      %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][weekday]
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
