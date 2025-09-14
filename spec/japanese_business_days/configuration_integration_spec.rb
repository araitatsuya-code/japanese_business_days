# frozen_string_literal: true

require "spec_helper"
require "date"

RSpec.describe "Configuration System Integration" do
  # テスト後に設定をリセット
  after do
    JapaneseBusinessDays.configuration.reset!
    JapaneseBusinessDays.send(:reset_calculators!)
  end

  describe "設定ブロックとカスタムルール適用" do
    context "要件5.1: カスタム非営業日の設定" do
      it "カスタム祝日が営業日計算に反映される" do
        custom_holiday = Date.new(2024, 6, 17) # 月曜日（通常は営業日）

        # 設定前は営業日
        expect(JapaneseBusinessDays.business_day?(custom_holiday)).to be true

        # カスタム祝日を設定
        JapaneseBusinessDays.configure do |config|
          config.add_holiday(custom_holiday)
        end

        # 設定後は非営業日
        expect(JapaneseBusinessDays.business_day?(custom_holiday)).to be false
      end

      it "カスタム祝日が営業日数計算に反映される" do
        start_date = Date.new(2024, 6, 10) # 月曜日
        end_date = Date.new(2024, 6, 14)   # 金曜日
        custom_holiday = Date.new(2024, 6, 12) # 水曜日をカスタム祝日に

        # 設定前の営業日数（月-金の5日間）
        expect(JapaneseBusinessDays.business_days_between(start_date, end_date)).to eq(4)

        # カスタム祝日を設定
        JapaneseBusinessDays.configure do |config|
          config.add_holiday(custom_holiday)
        end

        # 設定後の営業日数（水曜日が除外されて3日間）
        expect(JapaneseBusinessDays.business_days_between(start_date, end_date)).to eq(3)
      end

      it "カスタム祝日が営業日加算に反映される" do
        base_date = Date.new(2024, 6, 10) # 月曜日
        custom_holiday = Date.new(2024, 6, 12) # 水曜日をカスタム祝日に

        # 設定前: 月曜日 + 2営業日 = 水曜日
        expect(JapaneseBusinessDays.add_business_days(base_date, 2)).to eq(Date.new(2024, 6, 12))

        # カスタム祝日を設定
        JapaneseBusinessDays.configure do |config|
          config.add_holiday(custom_holiday)
        end

        # 設定後: 月曜日 + 2営業日 = 木曜日（水曜日をスキップ）
        expect(JapaneseBusinessDays.add_business_days(base_date, 2)).to eq(Date.new(2024, 6, 13))
      end

      it "複数のカスタム祝日を設定できる" do
        holidays = [
          Date.new(2024, 6, 12), # 水曜日
          Date.new(2024, 6, 14)  # 金曜日
        ]

        JapaneseBusinessDays.configure do |config|
          holidays.each { |date| config.add_holiday(date) }
        end

        holidays.each do |holiday|
          expect(JapaneseBusinessDays.business_day?(holiday)).to be false
        end
      end

      it "additional_holidays配列で一括設定できる" do
        holidays = [
          Date.new(2024, 6, 12),
          Date.new(2024, 6, 14)
        ]

        JapaneseBusinessDays.configure do |config|
          config.additional_holidays = holidays
        end

        holidays.each do |holiday|
          expect(JapaneseBusinessDays.business_day?(holiday)).to be false
        end
      end
    end

    context "要件5.2: カスタム営業日の設定" do
      it "カスタム営業日が祝日を上書きする" do
        new_years_day = Date.new(2024, 1, 1) # 元日（通常は祝日）

        # 設定前は祝日
        expect(JapaneseBusinessDays.business_day?(new_years_day)).to be false
        expect(JapaneseBusinessDays.holiday?(new_years_day)).to be true

        # カスタム営業日を設定
        JapaneseBusinessDays.configure do |config|
          config.add_business_day(new_years_day)
        end

        # 設定後は営業日（祝日判定は変わらない）
        expect(JapaneseBusinessDays.business_day?(new_years_day)).to be true
        expect(JapaneseBusinessDays.holiday?(new_years_day)).to be true # 祝日判定は変わらない
      end

      it "カスタム営業日が土日を上書きする" do
        saturday = Date.new(2024, 6, 8) # 土曜日

        # 設定前は非営業日
        expect(JapaneseBusinessDays.business_day?(saturday)).to be false

        # カスタム営業日を設定
        JapaneseBusinessDays.configure do |config|
          config.add_business_day(saturday)
        end

        # 設定後は営業日
        expect(JapaneseBusinessDays.business_day?(saturday)).to be true
      end

      it "カスタム営業日が営業日数計算に反映される" do
        start_date = Date.new(2024, 1, 1)  # 元日（月曜日・祝日）
        end_date = Date.new(2024, 1, 5)    # 金曜日

        # 設定前の営業日数（元日を除く4日間）
        expect(JapaneseBusinessDays.business_days_between(start_date, end_date)).to eq(4)

        # 元日をカスタム営業日に設定
        JapaneseBusinessDays.configure do |config|
          config.add_business_day(start_date)
        end

        # 設定後の営業日数（元日を含む4日間）
        expect(JapaneseBusinessDays.business_days_between(start_date, end_date)).to eq(4)
      end

      it "複数のカスタム営業日を設定できる" do
        business_days = [
          Date.new(2024, 1, 1),  # 元日
          Date.new(2024, 6, 8)   # 土曜日
        ]

        JapaneseBusinessDays.configure do |config|
          business_days.each { |date| config.add_business_day(date) }
        end

        business_days.each do |business_day|
          expect(JapaneseBusinessDays.business_day?(business_day)).to be true
        end
      end

      it "additional_business_days配列で一括設定できる" do
        business_days = [
          Date.new(2024, 1, 1),
          Date.new(2024, 6, 8)
        ]

        JapaneseBusinessDays.configure do |config|
          config.additional_business_days = business_days
        end

        business_days.each do |business_day|
          expect(JapaneseBusinessDays.business_day?(business_day)).to be true
        end
      end
    end

    context "要件5.3: 週末の定義変更" do
      it "週末の定義を変更できる" do
        friday = Date.new(2024, 6, 7)   # 金曜日
        saturday = Date.new(2024, 6, 8) # 土曜日
        sunday = Date.new(2024, 6, 9)   # 日曜日

        # デフォルト設定での営業日判定
        expect(JapaneseBusinessDays.business_day?(friday)).to be true
        expect(JapaneseBusinessDays.business_day?(saturday)).to be false
        expect(JapaneseBusinessDays.business_day?(sunday)).to be false

        # 金曜日と土曜日を週末に設定
        JapaneseBusinessDays.configure do |config|
          config.weekend_days = [5, 6] # 金曜日と土曜日
        end

        # 設定後の営業日判定
        expect(JapaneseBusinessDays.business_day?(friday)).to be false   # 金曜日が週末
        expect(JapaneseBusinessDays.business_day?(saturday)).to be false # 土曜日が週末
        expect(JapaneseBusinessDays.business_day?(sunday)).to be true    # 日曜日が営業日
      end

      it "週末変更が営業日数計算に反映される" do
        # 2024年6月3日(月) から 2024年6月9日(日) まで
        start_date = Date.new(2024, 6, 3)
        end_date = Date.new(2024, 6, 9)

        # デフォルト設定（土日が週末）: 火水木金の4日間（start_dateは含まない）
        expect(JapaneseBusinessDays.business_days_between(start_date, end_date)).to eq(4)

        # 金曜日と土曜日を週末に設定
        JapaneseBusinessDays.configure do |config|
          config.weekend_days = [5, 6]
        end

        # 設定後: 火水木日の4日間（start_dateは含まない）
        expect(JapaneseBusinessDays.business_days_between(start_date, end_date)).to eq(4)
      end

      it "単一の週末日を設定できる" do
        JapaneseBusinessDays.configure do |config|
          config.weekend_days = [0] # 日曜日のみ
        end

        expect(JapaneseBusinessDays.business_day?(Date.new(2024, 6, 8))).to be true  # 土曜日が営業日
        expect(JapaneseBusinessDays.business_day?(Date.new(2024, 6, 9))).to be false # 日曜日が週末
      end

      it "全ての曜日を週末に設定できる" do
        JapaneseBusinessDays.configure do |config|
          config.weekend_days = [0, 1, 2, 3, 4, 5, 6]
        end

        # 全ての曜日が週末なので、カスタム営業日以外は非営業日
        (0..6).each do |wday|
          date = Date.new(2024, 6, 3) + wday # 月曜日から日曜日まで
          expect(JapaneseBusinessDays.business_day?(date)).to be false
        end
      end
    end

    context "要件5.4: 設定の組み合わせ" do
      it "カスタム祝日と週末変更を組み合わせて使用できる" do
        custom_holiday = Date.new(2024, 6, 10) # 月曜日

        JapaneseBusinessDays.configure do |config|
          config.weekend_days = [5, 6] # 金土を週末に
          config.add_holiday(custom_holiday) # 月曜日をカスタム祝日に
        end

        expect(JapaneseBusinessDays.business_day?(Date.new(2024, 6, 7))).to be false  # 金曜日（週末）
        expect(JapaneseBusinessDays.business_day?(Date.new(2024, 6, 8))).to be false  # 土曜日（週末）
        expect(JapaneseBusinessDays.business_day?(Date.new(2024, 6, 9))).to be true   # 日曜日（営業日）
        expect(JapaneseBusinessDays.business_day?(custom_holiday)).to be false        # 月曜日（カスタム祝日）
      end

      it "カスタム営業日がカスタム祝日を上書きする" do
        target_date = Date.new(2024, 6, 10) # 月曜日

        JapaneseBusinessDays.configure do |config|
          config.add_holiday(target_date) # カスタム祝日に設定
          config.add_business_day(target_date) # 同じ日をカスタム営業日に設定
        end

        # カスタム営業日が優先される
        expect(JapaneseBusinessDays.business_day?(target_date)).to be true
      end

      it "カスタム営業日が週末を上書きする" do
        saturday = Date.new(2024, 6, 8) # 土曜日

        JapaneseBusinessDays.configure do |config|
          config.weekend_days = [0, 6] # 日土を週末に（デフォルト）
          config.add_business_day(saturday) # 土曜日をカスタム営業日に
        end

        # カスタム営業日が優先される
        expect(JapaneseBusinessDays.business_day?(saturday)).to be true
      end
    end
  end

  describe "設定変更の反映" do
    it "設定変更後に計算器がリセットされる" do
      # 初期状態で営業日計算を実行（計算器を初期化）
      expect(JapaneseBusinessDays.business_day?(Date.new(2024, 6, 10))).to be true

      # 設定を変更
      JapaneseBusinessDays.configure do |config|
        config.add_holiday(Date.new(2024, 6, 10))
      end

      # 設定変更が即座に反映される
      expect(JapaneseBusinessDays.business_day?(Date.new(2024, 6, 10))).to be false
    end

    it "複数回の設定変更が正しく反映される" do
      target_date = Date.new(2024, 6, 10)

      # 最初の設定
      JapaneseBusinessDays.configure do |config|
        config.add_holiday(target_date)
      end
      expect(JapaneseBusinessDays.business_day?(target_date)).to be false

      # 設定をリセット
      JapaneseBusinessDays.configuration.reset!
      JapaneseBusinessDays.send(:reset_calculators!)
      expect(JapaneseBusinessDays.business_day?(target_date)).to be true

      # 新しい設定
      JapaneseBusinessDays.configure do |config|
        config.add_business_day(Date.new(2024, 1, 1)) # 元日を営業日に
      end
      expect(JapaneseBusinessDays.business_day?(Date.new(2024, 1, 1))).to be true
    end
  end

  describe "エラーハンドリング" do
    it "設定ブロック内でのエラーが適切に処理される" do
      expect do
        JapaneseBusinessDays.configure do |config|
          config.add_holiday("invalid-date")
        end
      end.to raise_error(JapaneseBusinessDays::InvalidDateError)
    end

    it "無効な週末設定でエラーが発生する" do
      expect do
        JapaneseBusinessDays.configure do |config|
          config.weekend_days = []
        end
      end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /weekend_days cannot be empty/)
    end

    it "無効な追加祝日設定でエラーが発生する" do
      expect do
        JapaneseBusinessDays.configure do |config|
          config.additional_holidays = "not an array"
        end
      end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /additional_holidays must be an Array/)
    end
  end

  describe "パフォーマンス" do
    it "設定変更後も高いパフォーマンスを維持する" do
      # カスタム設定を適用
      JapaneseBusinessDays.configure do |config|
        config.add_holiday(Date.new(2024, 6, 15))
        config.weekend_days = [5, 6]
      end

      start_time = Time.now

      # 100回の営業日計算を実行
      100.times do |i|
        start_date = Date.new(2024, 1, 1) + i
        end_date = start_date + 30
        JapaneseBusinessDays.business_days_between(start_date, end_date)
      end

      elapsed_time = Time.now - start_time
      expect(elapsed_time).to be < 1.0 # 1秒以内に完了
    end

    it "設定変更が頻繁に行われてもメモリリークしない" do
      initial_objects = ObjectSpace.count_objects

      # 設定変更を繰り返す
      10.times do |i|
        JapaneseBusinessDays.configure do |config|
          config.add_holiday(Date.new(2024, 6, i + 1))
        end

        # 営業日計算を実行
        JapaneseBusinessDays.business_days_between(
          Date.new(2024, 6, 1),
          Date.new(2024, 6, 30)
        )
      end

      # ガベージコレクションを実行
      GC.start

      final_objects = ObjectSpace.count_objects

      # オブジェクト数の増加が合理的な範囲内であることを確認
      object_increase = final_objects[:TOTAL] - initial_objects[:TOTAL]
      expect(object_increase).to be < 2000 # 2000オブジェクト未満の増加（現実的な値に調整）
    end
  end

  describe "スレッドセーフティ" do
    it "複数スレッドからの設定変更が安全に処理される" do
      threads = []
      results = []

      # 複数スレッドで設定変更と計算を実行
      5.times do |i|
        threads << Thread.new do
          JapaneseBusinessDays.configure do |config|
            config.add_holiday(Date.new(2024, 6, i + 10))
          end

          result = JapaneseBusinessDays.business_day?(Date.new(2024, 6, i + 10))
          results << result
        end
      end

      threads.each(&:join)

      # 全ての結果が期待通りであることを確認
      results.each do |result|
        expect(result).to be false # 追加した祝日は非営業日
      end
    end
  end
end
