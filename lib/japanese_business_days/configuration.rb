# frozen_string_literal: true

module JapaneseBusinessDays
  # カスタムルールの設定を管理するクラス
  class Configuration
    attr_accessor :additional_holidays, :additional_business_days, :weekend_days

    def initialize
      @additional_holidays = []
      @additional_business_days = []
      @weekend_days = [0, 6] # 日曜日、土曜日
    end

    # カスタム祝日追加
    # @param date [Date, Time, DateTime, String] 追加する祝日
    def add_holiday(date)
      raise NotImplementedError, "This method will be implemented in task 2.3"
    end

    # カスタム営業日追加（祝日の上書き）
    # @param date [Date, Time, DateTime, String] 追加する営業日
    def add_business_day(date)
      raise NotImplementedError, "This method will be implemented in task 2.3"
    end

    # 週末の定義変更
    # @param days [Array<Integer>] 週末とする曜日の配列（0=日曜, 6=土曜）
    def weekend_days=(days)
      raise NotImplementedError, "This method will be implemented in task 2.3"
    end
  end
end