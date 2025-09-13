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
    # @return [Array<Holiday>] キャッシュされた祝日リスト
    def cached_holidays_for_year(year)
      raise NotImplementedError, "This method will be implemented in task 4.1"
    end

    # 祝日データをキャッシュに保存
    # @param year [Integer] 対象年
    # @param holidays [Array<Holiday>] 祝日リスト
    def store_holidays_for_year(year, holidays)
      raise NotImplementedError, "This method will be implemented in task 4.1"
    end

    # キャッシュクリア
    def clear_cache
      raise NotImplementedError, "This method will be implemented in task 4.1"
    end

    # 特定年のキャッシュクリア
    # @param year [Integer] 対象年
    def clear_cache_for_year(year)
      raise NotImplementedError, "This method will be implemented in task 4.1"
    end

    private

    # キャッシュサイズ管理
    def manage_cache_size
      raise NotImplementedError, "This method will be implemented in task 4.2"
    end

    # キャッシュヒット判定
    def cache_hit?(year)
      raise NotImplementedError, "This method will be implemented in task 4.1"
    end
  end
end