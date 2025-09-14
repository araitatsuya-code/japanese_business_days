# frozen_string_literal: true

module JapaneseBusinessDays
  # 祝日データのキャッシュを管理し、パフォーマンスを向上させるクラス
  class CacheManager
    DEFAULT_MAX_CACHE_SIZE = 10

    # @param max_cache_size [Integer] 最大キャッシュサイズ
    def initialize(max_cache_size: DEFAULT_MAX_CACHE_SIZE)
      @cache = {}
      @max_cache_size = max_cache_size
      @access_order = [] # LRU用のアクセス順序管理
      @access_count = {} # アクセス頻度管理
    end

    # 年間祝日キャッシュ（O(1)アクセス）
    # @param year [Integer] 対象年
    # @return [Array<Holiday>, nil] キャッシュされた祝日リスト、キャッシュにない場合はnil
    def cached_holidays_for_year(year)
      validate_year!(year)
      
      if @cache.key?(year)
        # LRU更新: アクセス順序を更新
        update_access_order(year)
        # アクセス頻度を更新
        @access_count[year] = (@access_count[year] || 0) + 1
        @cache[year]
      else
        nil
      end
    end

    # 祝日データをキャッシュに保存（効率的なメモリ管理）
    # @param year [Integer] 対象年
    # @param holidays [Array<Holiday>] 祝日リスト
    def store_holidays_for_year(year, holidays)
      validate_year!(year)
      validate_holidays!(holidays)
      
      # キャッシュサイズ管理（事前チェック）
      manage_cache_size_before_insert(year)
      
      # メモリ効率化: 祝日配列を凍結してコピーを防ぐ
      @cache[year] = holidays.freeze
      
      # アクセス管理の更新
      update_access_order(year)
      @access_count[year] = (@access_count[year] || 0) + 1
    end

    # キャッシュクリア
    def clear_cache
      @cache.clear
      @access_order.clear
      @access_count.clear
    end

    # 特定年のキャッシュクリア
    # @param year [Integer] 対象年
    def clear_cache_for_year(year)
      validate_year!(year)
      @cache.delete(year)
      @access_order.delete(year)
      @access_count.delete(year)
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

    # キャッシュ統計情報
    # @return [Hash] キャッシュのパフォーマンス統計
    def cache_stats
      {
        size: @cache.size,
        max_size: @max_cache_size,
        hit_rate: calculate_hit_rate,
        most_accessed_year: most_accessed_year,
        memory_usage: estimate_memory_usage
      }
    end

    # 特定の年の祝日が高速アクセス可能かチェック
    # @param year [Integer] 対象年
    # @return [Boolean] O(1)でアクセス可能な場合true
    def fast_access_available?(year)
      @cache.key?(year)
    end

    private

    # キャッシュサイズ管理（挿入前チェック）
    def manage_cache_size_before_insert(new_year)
      return if @cache.size < @max_cache_size || @cache.key?(new_year)
      
      # LRU + 頻度ベースの効率的な削除アルゴリズム
      evict_least_valuable_entry
    end

    # 最も価値の低いエントリを削除
    def evict_least_valuable_entry
      # アクセス頻度が最も低く、最近アクセスされていないエントリを選択
      candidate_year = find_eviction_candidate
      
      if candidate_year
        @cache.delete(candidate_year)
        @access_order.delete(candidate_year)
        @access_count.delete(candidate_year)
      end
    end

    # 削除候補を効率的に見つける
    def find_eviction_candidate
      # アクセス頻度が1以下で最も古いものを優先
      low_frequency_years = @access_count.select { |_, count| count <= 1 }.keys
      
      if low_frequency_years.any?
        # 最も古いアクセスのものを選択
        low_frequency_years.min_by { |year| @access_order.index(year) || Float::INFINITY }
      else
        # 全て頻繁にアクセスされている場合は最も古いものを削除
        @access_order.first
      end
    end

    # アクセス順序を効率的に更新（O(1)操作）
    def update_access_order(year)
      @access_order.delete(year) # 既存位置から削除
      @access_order.push(year)   # 最新位置に追加
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

    # ヒット率を計算
    def calculate_hit_rate
      total_accesses = @access_count.values.sum
      return 0.0 if total_accesses == 0
      
      cache_hits = @access_count.size
      (cache_hits.to_f / total_accesses * 100).round(2)
    end

    # 最もアクセスされた年を取得
    def most_accessed_year
      return nil if @access_count.empty?
      
      @access_count.max_by { |_, count| count }&.first
    end

    # メモリ使用量の概算
    def estimate_memory_usage
      base_size = @cache.size * 100 # 概算: 年あたり100バイト
      access_overhead = (@access_order.size + @access_count.size) * 20 # 管理データ
      
      "#{base_size + access_overhead} bytes (estimated)"
    end
  end
end