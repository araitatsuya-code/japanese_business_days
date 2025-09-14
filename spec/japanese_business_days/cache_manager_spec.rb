# frozen_string_literal: true

require "spec_helper"

RSpec.describe JapaneseBusinessDays::CacheManager do
  let(:cache_manager) { described_class.new }
  let(:holiday1) { JapaneseBusinessDays::Holiday.new(Date.new(2024, 1, 1), "元日", :fixed) }
  let(:holiday2) { JapaneseBusinessDays::Holiday.new(Date.new(2024, 2, 11), "建国記念の日", :fixed) }
  let(:holidays_2024) { [holiday1, holiday2] }

  describe "#initialize" do
    it "デフォルトの最大キャッシュサイズで初期化される" do
      expect(cache_manager.instance_variable_get(:@max_cache_size)).to eq(10)
      expect(cache_manager.cache_size).to eq(0)
    end

    it "カスタムの最大キャッシュサイズで初期化できる" do
      custom_cache_manager = described_class.new(max_cache_size: 5)
      expect(custom_cache_manager.instance_variable_get(:@max_cache_size)).to eq(5)
    end
  end

  describe "#cached_holidays_for_year" do
    context "キャッシュにデータがある場合" do
      before do
        cache_manager.store_holidays_for_year(2024, holidays_2024)
      end

      it "キャッシュされた祝日リストを返す" do
        result = cache_manager.cached_holidays_for_year(2024)
        expect(result).to eq(holidays_2024)
      end
    end

    context "キャッシュにデータがない場合" do
      it "nilを返す" do
        result = cache_manager.cached_holidays_for_year(2024)
        expect(result).to be_nil
      end
    end

    context "無効な年が渡された場合" do
      it "ArgumentErrorを発生させる" do
        expect { cache_manager.cached_holidays_for_year("invalid") }
          .to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Year must be a positive integer/)
      end

      it "負の数の場合ArgumentErrorを発生させる" do
        expect { cache_manager.cached_holidays_for_year(-1) }
          .to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Year must be a positive integer/)
      end
    end
  end

  describe "#store_holidays_for_year" do
    it "祝日データをキャッシュに保存する" do
      cache_manager.store_holidays_for_year(2024, holidays_2024)
      
      expect(cache_manager.cached_holidays_for_year(2024)).to eq(holidays_2024)
      expect(cache_manager.cache_size).to eq(1)
    end

    it "保存されたデータは凍結される" do
      cache_manager.store_holidays_for_year(2024, holidays_2024)
      cached_data = cache_manager.cached_holidays_for_year(2024)
      
      expect(cached_data).to be_frozen
    end

    context "無効な年が渡された場合" do
      it "ArgumentErrorを発生させる" do
        expect { cache_manager.store_holidays_for_year("invalid", holidays_2024) }
          .to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Year must be a positive integer/)
      end
    end

    context "無効な祝日リストが渡された場合" do
      it "配列でない場合ArgumentErrorを発生させる" do
        expect { cache_manager.store_holidays_for_year(2024, "invalid") }
          .to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Holidays must be an array/)
      end

      it "Holiday以外のオブジェクトが含まれる場合ArgumentErrorを発生させる" do
        invalid_holidays = [holiday1, "invalid", holiday2]
        expect { cache_manager.store_holidays_for_year(2024, invalid_holidays) }
          .to raise_error(JapaneseBusinessDays::InvalidArgumentError, /All elements must be Holiday objects/)
      end
    end
  end

  describe "#clear_cache" do
    before do
      cache_manager.store_holidays_for_year(2024, holidays_2024)
      cache_manager.store_holidays_for_year(2025, [])
    end

    it "すべてのキャッシュをクリアする" do
      expect(cache_manager.cache_size).to eq(2)
      
      cache_manager.clear_cache
      
      expect(cache_manager.cache_size).to eq(0)
      expect(cache_manager.cached_holidays_for_year(2024)).to be_nil
      expect(cache_manager.cached_holidays_for_year(2025)).to be_nil
    end
  end

  describe "#clear_cache_for_year" do
    before do
      cache_manager.store_holidays_for_year(2024, holidays_2024)
      cache_manager.store_holidays_for_year(2025, [])
    end

    it "指定した年のキャッシュのみクリアする" do
      cache_manager.clear_cache_for_year(2024)
      
      expect(cache_manager.cached_holidays_for_year(2024)).to be_nil
      expect(cache_manager.cached_holidays_for_year(2025)).to eq([])
      expect(cache_manager.cache_size).to eq(1)
    end

    context "無効な年が渡された場合" do
      it "ArgumentErrorを発生させる" do
        expect { cache_manager.clear_cache_for_year("invalid") }
          .to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Year must be a positive integer/)
      end
    end
  end

  describe "#cache_size" do
    it "キャッシュサイズを返す" do
      expect(cache_manager.cache_size).to eq(0)
      
      cache_manager.store_holidays_for_year(2024, holidays_2024)
      expect(cache_manager.cache_size).to eq(1)
      
      cache_manager.store_holidays_for_year(2025, [])
      expect(cache_manager.cache_size).to eq(2)
    end
  end

  describe "#cached_years" do
    it "キャッシュされている年のソート済みリストを返す" do
      expect(cache_manager.cached_years).to eq([])
      
      cache_manager.store_holidays_for_year(2025, [])
      cache_manager.store_holidays_for_year(2024, holidays_2024)
      cache_manager.store_holidays_for_year(2023, [])
      
      expect(cache_manager.cached_years).to eq([2023, 2024, 2025])
    end
  end

  describe "基本的なキャッシュサイズ管理" do
    let(:small_cache_manager) { described_class.new(max_cache_size: 2) }

    it "最大キャッシュサイズを超えた場合、最も古いエントリを削除する" do
      # 最大サイズまでキャッシュを埋める
      small_cache_manager.store_holidays_for_year(2022, [])
      small_cache_manager.store_holidays_for_year(2023, [])
      expect(small_cache_manager.cache_size).to eq(2)
      expect(small_cache_manager.cached_years).to eq([2022, 2023])
      
      # 新しいエントリを追加すると最も古いものが削除される
      small_cache_manager.store_holidays_for_year(2024, holidays_2024)
      expect(small_cache_manager.cache_size).to eq(2)
      expect(small_cache_manager.cached_years).to eq([2023, 2024])
      expect(small_cache_manager.cached_holidays_for_year(2022)).to be_nil
    end
  end

  describe "private methods" do
    describe "#cache_hit?" do
      it "キャッシュにヒットした場合trueを返す" do
        expect(cache_manager.send(:cache_hit?, 2024)).to be false
        
        cache_manager.store_holidays_for_year(2024, holidays_2024)
        expect(cache_manager.send(:cache_hit?, 2024)).to be true
      end
    end
  end
end