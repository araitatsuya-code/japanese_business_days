# frozen_string_literal: true

module JapaneseBusinessDays
  # 日本の祝日情報を表すクラス
  #
  # このクラスは、日本の祝日の詳細情報（日付、名前、種類）を保持します。
  # 祝日の種類により、固定祝日、計算祝日、ハッピーマンデー祝日、振替休日を区別できます。
  #
  # @example 祝日オブジェクトの作成
  #   holiday = JapaneseBusinessDays::Holiday.new(
  #     Date.new(2024, 1, 1),
  #     "元日",
  #     :fixed
  #   )
  #   puts holiday.to_s  # => "2024-01-01 - 元日 (fixed)"
  #
  # @example 祝日の種類による分類
  #   holidays = JapaneseBusinessDays.holidays_in_year(2024)
  #   fixed_holidays = holidays.select { |h| h.type == :fixed }
  #   happy_monday_holidays = holidays.select { |h| h.type == :happy_monday }
  #
  # @author JapaneseBusinessDays Team
  # @since 0.1.0
  class Holiday
    attr_reader :date, :name, :type

    # 有効な祝日タイプ
    VALID_TYPES = [:fixed, :calculated, :happy_monday, :substitute].freeze

    # 祝日オブジェクトを初期化します
    #
    # @param date [Date] 祝日の日付
    # @param name [String] 祝日名（空でない文字列）
    # @param type [Symbol] 祝日の種類（:fixed, :calculated, :happy_monday, :substitute）
    # @raise [InvalidArgumentError] 無効な引数の場合
    # @example 固定祝日の作成
    #   holiday = Holiday.new(Date.new(2024, 1, 1), "元日", :fixed)
    # @example ハッピーマンデー祝日の作成
    #   holiday = Holiday.new(Date.new(2024, 1, 8), "成人の日", :happy_monday)
    # @since 0.1.0
    def initialize(date, name, type)
      validate_date!(date)
      validate_name!(name)
      validate_type!(type)
      
      @date = date
      @name = name
      @type = type
    end

    # 祝日の文字列表現を返します
    #
    # @return [String] "日付 - 祝日名 (種類)" の形式の文字列
    # @example 文字列表現の取得
    #   holiday = Holiday.new(Date.new(2024, 1, 1), "元日", :fixed)
    #   holiday.to_s  # => "2024-01-01 - 元日 (fixed)"
    # @since 0.1.0
    def to_s
      "#{@date} - #{@name} (#{@type})"
    end

    # 他の祝日オブジェクトと等価かどうかを判定します
    #
    # 日付、名前、種類がすべて一致する場合にtrueを返します。
    #
    # @param other [Holiday] 比較対象の祝日オブジェクト
    # @return [Boolean] 同じ祝日の場合true、そうでなければfalse
    # @example 祝日の比較
    #   holiday1 = Holiday.new(Date.new(2024, 1, 1), "元日", :fixed)
    #   holiday2 = Holiday.new(Date.new(2024, 1, 1), "元日", :fixed)
    #   holiday1 == holiday2  # => true
    # @since 0.1.0
    def ==(other)
      other.is_a?(Holiday) &&
        @date == other.date &&
        @name == other.name &&
        @type == other.type
    end

    alias eql? ==

    # ハッシュ値を計算します
    #
    # 日付、名前、種類を基にハッシュ値を計算し、HashやSetでの使用を可能にします。
    #
    # @return [Integer] ハッシュ値
    # @example HashやSetでの使用
    #   holidays = Set.new
    #   holidays << Holiday.new(Date.new(2024, 1, 1), "元日", :fixed)
    #   holidays.include?(Holiday.new(Date.new(2024, 1, 1), "元日", :fixed))  # => true
    # @since 0.1.0
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