# frozen_string_literal: true

require 'spec_helper'
require 'benchmark'

RSpec.describe JapaneseBusinessDays::CacheManager, 'Performance Tests' do
  let(:cache_manager) { described_class.new(max_cache_size: 100) }
  let(:sample_holidays) do
    [
      JapaneseBusinessDays::Holiday.new(Date.new(2024, 1, 1), "元日", :fixed),
      JapaneseBusinessDays::Holiday.new(Date.new(2024, 2, 11), "建国記念の日", :fixed),
      JapaneseBusinessDays::Holiday.new(Date.new(2024, 3, 20), "春分の日", :calculated)
    ]
  end

  describe 'キャッシュアクセスのパフォーマンス' do
    context 'O(1)時間計算量の検証' do
      it '単一年のキャッシュアクセスが一定時間で完了する' do
        # キャッシュにデータを保存
        cache_manager.store_holidays_for_year(2024, sample_holidays)
        
        # 複数回測定して平均を取る（測定の安定性向上）
        times = []
        5.times do
          times << measure_access_time(cache_manager, 2024, 1000)
        end
        average_time = times.sum / times.size
        
        # 1000回のアクセスが10ms以内で完了することを確認（O(1)の証明）
        expect(average_time).to be < 0.01 # 10ms以内
      end

      it '1000回のキャッシュアクセスが100ms以内に完了する' do
        cache_manager.store_holidays_for_year(2024, sample_holidays)
        
        time = Benchmark.realtime do
          1000.times do
            cache_manager.cached_holidays_for_year(2024)
          end
        end
        
        expect(time).to be < 0.1 # 100ms以内
      end
    end

    context 'メモリ効率性の検証' do
      it '大量データでもメモリ使用量が制限される' do
        initial_memory = get_memory_usage
        
        # 100年分のデータをキャッシュ
        (2000..2099).each do |year|
          holidays = generate_holidays_for_year(year)
          cache_manager.store_holidays_for_year(year, holidays)
        end
        
        final_memory = get_memory_usage
        memory_increase = final_memory - initial_memory
        
        # メモリ増加が合理的な範囲内（10MB以下）
        expect(memory_increase).to be < 10_000_000 # 10MB
      end

      it 'キャッシュサイズ制限が正しく機能する' do
        small_cache = described_class.new(max_cache_size: 5)
        
        # 制限を超えてデータを追加
        (2020..2030).each do |year|
          small_cache.store_holidays_for_year(year, sample_holidays)
        end
        
        # キャッシュサイズが制限内に収まっている
        expect(small_cache.cache_size).to eq(5)
      end
    end

    context 'LRUアルゴリズムの効率性' do
      it 'LRU削除が効率的に動作する' do
        small_cache = described_class.new(max_cache_size: 3)
        
        # キャッシュを満杯にする
        small_cache.store_holidays_for_year(2020, sample_holidays)
        small_cache.store_holidays_for_year(2021, sample_holidays)
        small_cache.store_holidays_for_year(2022, sample_holidays)
        
        # 2021にアクセスして最近使用済みにする
        small_cache.cached_holidays_for_year(2021)
        
        # 新しいエントリを追加（2020が削除されるべき）
        small_cache.store_holidays_for_year(2023, sample_holidays)
        
        expect(small_cache.fast_access_available?(2020)).to be false
        expect(small_cache.fast_access_available?(2021)).to be true
        expect(small_cache.fast_access_available?(2022)).to be true
        expect(small_cache.fast_access_available?(2023)).to be true
      end

      it 'アクセス頻度ベースの削除が効率的に動作する' do
        small_cache = described_class.new(max_cache_size: 3)
        
        # キャッシュを満杯にする
        small_cache.store_holidays_for_year(2020, sample_holidays)
        small_cache.store_holidays_for_year(2021, sample_holidays)
        small_cache.store_holidays_for_year(2022, sample_holidays)
        
        # 2021を頻繁にアクセス
        5.times { small_cache.cached_holidays_for_year(2021) }
        
        # 新しいエントリを追加（アクセス頻度の低い2020または2022が削除される）
        small_cache.store_holidays_for_year(2023, sample_holidays)
        
        # 頻繁にアクセスされた2021は残っているべき
        expect(small_cache.fast_access_available?(2021)).to be true
        expect(small_cache.fast_access_available?(2023)).to be true
      end
    end

    context 'キャッシュ統計とモニタリング' do
      it 'キャッシュ統計が正確に計算される' do
        cache_manager.store_holidays_for_year(2024, sample_holidays)
        cache_manager.cached_holidays_for_year(2024) # ヒット
        cache_manager.cached_holidays_for_year(2025) # ミス
        
        stats = cache_manager.cache_stats
        
        expect(stats[:size]).to eq(1)
        expect(stats[:max_size]).to eq(100)
        expect(stats[:most_accessed_year]).to eq(2024)
        expect(stats[:memory_usage]).to be_a(String)
      end
    end

    context 'スレッドセーフティ（基本テスト）' do
      it '並行アクセスでデータ破損が発生しない' do
        threads = []
        results = []
        
        # 複数スレッドで同時にキャッシュ操作
        10.times do |i|
          threads << Thread.new do
            year = 2020 + i
            cache_manager.store_holidays_for_year(year, sample_holidays)
            results << cache_manager.cached_holidays_for_year(year)
          end
        end
        
        threads.each(&:join)
        
        # 全ての結果が正常に取得できている
        expect(results.compact.size).to eq(10)
        expect(cache_manager.cache_size).to eq(10)
      end
    end
  end

  describe 'ベンチマーク比較' do
    it 'キャッシュありとなしでパフォーマンス差を測定' do
      # キャッシュなしの場合（毎回計算）
      no_cache_time = Benchmark.realtime do
        1000.times do
          generate_holidays_for_year(2024) # 毎回計算
        end
      end
      
      # キャッシュありの場合
      cache_manager.store_holidays_for_year(2024, sample_holidays)
      
      with_cache_time = Benchmark.realtime do
        1000.times do
          cache_manager.cached_holidays_for_year(2024) # キャッシュから取得
        end
      end
      
      # キャッシュありの方が高速であるべき（より現実的な比較）
      expect(with_cache_time).to be < (no_cache_time * 0.5) # 2倍以上高速
    end
  end

  private

  def measure_access_time(cache, year, iterations)
    Benchmark.realtime do
      iterations.times do
        cache.cached_holidays_for_year(year)
      end
    end
  end

  def get_memory_usage
    # Rubyのメモリ使用量を取得（概算）
    GC.stat[:heap_allocated_pages] * GC::INTERNAL_CONSTANTS[:HEAP_PAGE_SIZE]
  rescue
    # フォールバック: プロセスメモリ使用量
    `ps -o rss= -p #{Process.pid}`.to_i * 1024
  rescue
    0 # 測定できない場合は0を返す
  end

  def generate_holidays_for_year(year)
    [
      JapaneseBusinessDays::Holiday.new(Date.new(year, 1, 1), "元日", :fixed),
      JapaneseBusinessDays::Holiday.new(Date.new(year, 2, 11), "建国記念の日", :fixed),
      JapaneseBusinessDays::Holiday.new(Date.new(year, 4, 29), "昭和の日", :fixed),
      JapaneseBusinessDays::Holiday.new(Date.new(year, 5, 3), "憲法記念日", :fixed),
      JapaneseBusinessDays::Holiday.new(Date.new(year, 5, 4), "みどりの日", :fixed),
      JapaneseBusinessDays::Holiday.new(Date.new(year, 5, 5), "こどもの日", :fixed)
    ]
  end
end