# frozen_string_literal: true

module JapaneseBusinessDays
  # 祝日情報を表すクラス
  class Holiday
    attr_reader :date, :name, :type

    # 有効な祝日タイプ
    VALID_TYPES = [:fixed, :calculated, :happy_monday, :substitute].freeze

    # @param date [Date] 祝日の日付
    # @param name [String] 祝日名
    # @param type [Symbol] 祝日の種類 (:fixed, :calculated, :happy_monday, :substitute)
    def initialize(date, name, type)
      validate_date!(date)
      validate_name!(name)
      validate_type!(type)
      
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

    private

    # 日付の検証
    # @param date [Date] 検証する日付
    # @raise [InvalidArgumentError] 無効な日付の場合
    def validate_date!(date)
      unless date.is_a?(Date)
        raise InvalidArgumentError, "Date must be a Date object, got #{date.class}"
      end
    end

    # 祝日名の検証
    # @param name [String] 検証する祝日名
    # @raise [InvalidArgumentError] 無効な祝日名の場合
    def validate_name!(name)
      unless name.is_a?(String) && !name.strip.empty?
        raise InvalidArgumentError, "Name must be a non-empty string, got #{name.inspect}"
      end
    end

    # 祝日タイプの検証
    # @param type [Symbol] 検証する祝日タイプ
    # @raise [InvalidArgumentError] 無効な祝日タイプの場合
    def validate_type!(type)
      unless VALID_TYPES.include?(type)
        raise InvalidArgumentError, "Type must be one of #{VALID_TYPES.join(', ')}, got #{type.inspect}"
      end
    end
  end
end