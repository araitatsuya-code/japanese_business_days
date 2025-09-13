# frozen_string_literal: true

module JapaneseBusinessDays
  # Date/Timeクラスの拡張を提供するモジュール
  module DateExtensions
    # 営業日加算
    # @param days [Integer] 加算する営業日数
    # @return [Date] 計算結果の日付
    def add_business_days(days)
      raise NotImplementedError, "This method will be implemented in task 6.1"
    end

    # 営業日減算
    # @param days [Integer] 減算する営業日数
    # @return [Date] 計算結果の日付
    def subtract_business_days(days)
      raise NotImplementedError, "This method will be implemented in task 6.1"
    end

    # 営業日判定
    # @return [Boolean] 営業日の場合true
    def business_day?
      raise NotImplementedError, "This method will be implemented in task 6.1"
    end

    # 祝日判定
    # @return [Boolean] 祝日の場合true
    def holiday?
      raise NotImplementedError, "This method will be implemented in task 6.1"
    end

    # 次の営業日
    # @return [Date] 次の営業日
    def next_business_day
      raise NotImplementedError, "This method will be implemented in task 6.1"
    end

    # 前の営業日
    # @return [Date] 前の営業日
    def previous_business_day
      raise NotImplementedError, "This method will be implemented in task 6.1"
    end
  end
end