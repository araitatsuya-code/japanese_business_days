# frozen_string_literal: true

module JapaneseBusinessDays
  # 日本の祝日計算を担当するクラス
  class HolidayCalculator
    # 祝日判定
    # @param date [Date] 判定する日付
    # @return [Boolean] 祝日の場合true
    def holiday?(date)
      raise NotImplementedError, "This method will be implemented in task 3.1"
    end

    # 年間祝日リスト
    # @param year [Integer] 対象年
    # @return [Array<Holiday>] その年の祝日リスト
    def holidays_in_year(year)
      raise NotImplementedError, "This method will be implemented in task 3.1"
    end

    # 振替休日判定
    # @param date [Date] 判定する日付
    # @return [Boolean] 振替休日の場合true
    def substitute_holiday?(date)
      raise NotImplementedError, "This method will be implemented in task 3.5"
    end

    private

    # 固定祝日
    def fixed_holidays(year)
      raise NotImplementedError, "This method will be implemented in task 3.2"
    end

    # 移動祝日（春分の日、秋分の日など）
    def calculated_holidays(year)
      raise NotImplementedError, "This method will be implemented in task 3.3"
    end

    # ハッピーマンデー祝日
    def happy_monday_holidays(year)
      raise NotImplementedError, "This method will be implemented in task 3.4"
    end
  end
end