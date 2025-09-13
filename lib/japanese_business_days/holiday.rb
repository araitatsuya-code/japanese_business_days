# frozen_string_literal: true

module JapaneseBusinessDays
  # 祝日情報を表すクラス
  class Holiday
    attr_reader :date, :name, :type

    # @param date [Date] 祝日の日付
    # @param name [String] 祝日名
    # @param type [Symbol] 祝日の種類 (:fixed, :calculated, :happy_monday, :substitute)
    def initialize(date, name, type)
      @date = date
      @name = name
      @type = type
    end

    # @return [String] 祝日の文字列表現
    def to_s
      "#{@date} - #{@name} (#{@type})"
    end

    # @param other [Holiday] 比較対象
    # @return [Boolean] 同じ祝日かどうか
    def ==(other)
      other.is_a?(Holiday) &&
        @date == other.date &&
        @name == other.name &&
        @type == other.type
    end

    alias eql? ==

    # @return [Integer] ハッシュ値
    def hash
      [@date, @name, @type].hash
    end
  end
end