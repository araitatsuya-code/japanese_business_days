# frozen_string_literal: true

module JapaneseBusinessDays
  # 祝日データのキャッシュを管理し、パフォーマンスを向上させるクラス
  class CacheManager
    DEFAULT_MAX_CACHE_SIZE = 10

    # @param max_cache_size [Integer] 最大キャッシュサイズ
    def initialize(max_cache_size: DEFAULT_MAX_CACHE_SIZE)
      @cache = {}
      @max_cache_size = max_cache_size
    end

    # 年間祝日キャッシュ
    # @param year [Integer] 対象年
    # @return [Array<Holiday>, nil] キャッシュされた祝日リスト、キャッシュにない場合はnil
    def cached_holidays_for_year(year)
      validate_year!(year)
      @cache[year]
    end

    # 祝日データをキャッシュに保存
    # @param year [Integer] 対象年
    # @param holidays [Array<Holiday>] 祝日リスト
    def store_holidays_for_year(year, holidays)
      validate_year!(year)
      validate_holidays!(holidays)
      
      manage_cache_size
      @cache[year] = holidays.freeze
    end

    # キャッシュクリア
    def clear_cache
      @cache.clear
    end

    # 特定年のキャッシュクリア
    # @param year [Integer] 対象年
    def clear_cache_for_year(year)
      validate_year!(year)
      @cache.delete(year)
    end

    # キャッシュサイズ取得
    # @return [Integer] 現在のキャッシュサイズ
    def cache_size
      @cache.size
    end

    # キャッシュされている年のリスト
    # @return [Array<Integer>] キャッシュされている年のリスト
    def cached_years
      @cache.keys.sort
    end

    private

    # キャッシュサイズ管理（基本実装）
    def manage_cache_size
      return if @cache.size < @max_cache_size
      
      # 最も古いエントリを削除（FIFO方式）
      oldest_key = @cache.keys.first
      @cache.delete(oldest_key)
    end

    # キャッシュヒット判定
    # @param year [Integer] 対象年
    # @return [Boolean] キャッシュにヒットした場合true
    def cache_hit?(year)
      @cache.key?(year)
    end

    # 年の検証
    # @param year [Integer] 検証する年
    # @raise [InvalidArgumentError] 無効な年の場合
    def validate_year!(year)
      unless year.is_a?(Integer) && year > 0
        raise InvalidArgumentError, "Year must be a positive integer, got #{year.inspect}"
      end
    end

    # 祝日リストの検証
    # @param holidays [Array<Holiday>] 検証する祝日リスト
    # @raise [InvalidArgumentError] 無効な祝日リストの場合
    def validate_holidays!(holidays)
      unless holidays.is_a?(Array)
        raise InvalidArgumentError, "Holidays must be an array, got #{holidays.class}"
      end
      
      holidays.each_with_index do |holiday, index|
        unless holiday.is_a?(Holiday)
          raise InvalidArgumentError, "All elements must be Holiday objects, got #{holiday.class} at index #{index}"
        end
      end
    end
  end
end