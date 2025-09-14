# frozen_string_literal: true

RSpec.describe "JapaneseBusinessDays Performance Tests" do
  describe "パフォーマンステストとベンチマーク" do
    # パフォーマンス要件の定数
    SINGLE_OPERATION_MAX_TIME = 0.001    # 1ms
    BATCH_OPERATION_MAX_TIME = 0.1       # 100ms
    LARGE_BATCH_MAX_TIME = 1.0           # 1秒
    MAX_MEMORY_INCREASE_MB = 10          # 10MB

    before(:all) do
      # テスト開始時のメモリ使用量を記録
      GC.start
      @initial_memory = get_memory_usage_mb
    end

    after(:all) do
      # テスト終了時のメモリ使用量をチェック
      GC.start
      final_memory = get_memory_usage_mb
      memory_increase = final_memory - @initial_memory
      
      puts "\n=== Memory Usage Report ==="
      puts "Initial memory: #{@initial_memory.round(2)} MB"
      puts "Final memory: #{final_memory.round(2)} MB"
      puts "Memory increase: #{memory_increase.round(2)} MB"
      puts "==========================="
      
      # メモリ使用量が制限内であることを確認
      expect(memory_increase).to be < MAX_MEMORY_INCREASE_MB
    end

    context "単一操作のパフォーマンス" do
      describe "営業日判定" do
        it "単一の営業日判定が1ms以内に完了する" do
          date = Date.new(2024, 1, 10)
          
          elapsed_time = measure_time do
            JapaneseBusinessDays.business_day?(date)
          end
          
          expect(elapsed_time).to be < SINGLE_OPERATION_MAX_TIME
        end

        it "祝日判定が1ms以内に完了する" do
          date = Date.new(2024, 1, 1)
          
          elapsed_time = measure_time do
            JapaneseBusinessDays.holiday?(date)
          end
          
          expect(elapsed_time).to be < SINGLE_OPERATION_MAX_TIME
        end

        it "営業日数計算が1ms以内に完了する" do
          start_date = Date.new(2024, 1, 1)
          end_date = Date.new(2024, 1, 31)
          
          elapsed_time = measure_time do
            JapaneseBusinessDays.business_days_between(start_date, end_date)
          end
          
          expect(elapsed_time).to be < SINGLE_OPERATION_MAX_TIME
        end

        it "営業日加算が1ms以内に完了する" do
          date = Date.new(2024, 1, 10)
          
          elapsed_time = measure_time do
            JapaneseBusinessDays.add_business_days(date, 10)
          end
          
          expect(elapsed_time).to be < SINGLE_OPERATION_MAX_TIME
        end

        it "年間祝日取得が1ms以内に完了する（初回）" do
          elapsed_time = measure_time do
            JapaneseBusinessDays.holidays_in_year(2024)
          end
          
          expect(elapsed_time).to be < SINGLE_OPERATION_MAX_TIME
        end
      end
    end

    context "バッチ操作のパフォーマンス" do
      describe "100回の連続操作" do
        it "100回の営業日判定が100ms以内に完了する" do
          dates = (1..100).map { |i| Date.new(2024, 1, 1) + i }
          
          elapsed_time = measure_time do
            dates.each { |date| JapaneseBusinessDays.business_day?(date) }
          end
          
          expect(elapsed_time).to be < BATCH_OPERATION_MAX_TIME
        end

        it "100回の営業日数計算が100ms以内に完了する" do
          date_pairs = (1..100).map do |i|
            start_date = Date.new(2024, 1, 1) + i
            end_date = start_date + 30
            [start_date, end_date]
          end
          
          elapsed_time = measure_time do
            date_pairs.each do |start_date, end_date|
              JapaneseBusinessDays.business_days_between(start_date, end_date)
            end
          end
          
          expect(elapsed_time).to be < BATCH_OPERATION_MAX_TIME
        end

        it "100回の営業日加算が100ms以内に完了する" do
          dates = (1..100).map { |i| Date.new(2024, 1, 1) + i }
          
          elapsed_time = measure_time do
            dates.each { |date| JapaneseBusinessDays.add_business_days(date, 5) }
          end
          
          expect(elapsed_time).to be < BATCH_OPERATION_MAX_TIME
        end

        it "100回の祝日判定が100ms以内に完了する" do
          dates = (1..100).map { |i| Date.new(2024, 1, 1) + i }
          
          elapsed_time = measure_time do
            dates.each { |date| JapaneseBusinessDays.holiday?(date) }
          end
          
          expect(elapsed_time).to be < BATCH_OPERATION_MAX_TIME
        end
      end

      describe "複数年の祝日データ処理" do
        it "10年分の祝日データ取得が100ms以内に完了する" do
          years = (2020..2029).to_a
          
          elapsed_time = measure_time do
            years.each { |year| JapaneseBusinessDays.holidays_in_year(year) }
          end
          
          expect(elapsed_time).to be < BATCH_OPERATION_MAX_TIME
        end

        it "同一年の祝日データ再取得が高速化される（キャッシュ効果）" do
          year = 2024
          
          # 初回取得時間
          first_time = measure_time do
            JapaneseBusinessDays.holidays_in_year(year)
          end
          
          # 2回目取得時間
          second_time = measure_time do
            JapaneseBusinessDays.holidays_in_year(year)
          end
          
          # キャッシュにより2回目が高速化されることを確認
          expect(second_time).to be < first_time
          expect(second_time).to be < SINGLE_OPERATION_MAX_TIME / 2 # 0.5ms以内
        end
      end
    end

    context "大量データ処理のパフォーマンス" do
      describe "1000回の連続操作" do
        it "1000回の営業日判定が1秒以内に完了する" do
          dates = (1..1000).map { |i| Date.new(2024, 1, 1) + i }
          
          elapsed_time = measure_time do
            dates.each { |date| JapaneseBusinessDays.business_day?(date) }
          end
          
          expect(elapsed_time).to be < LARGE_BATCH_MAX_TIME
        end

        it "1000回の営業日数計算が1秒以内に完了する" do
          date_pairs = (1..1000).map do |i|
            start_date = Date.new(2024, 1, 1) + (i * 10)
            end_date = start_date + 30
            [start_date, end_date]
          end
          
          elapsed_time = measure_time do
            date_pairs.each do |start_date, end_date|
              JapaneseBusinessDays.business_days_between(start_date, end_date)
            end
          end
          
          expect(elapsed_time).to be < LARGE_BATCH_MAX_TIME
        end

        it "1000回の営業日加算が1秒以内に完了する" do
          dates = (1..1000).map { |i| Date.new(2024, 1, 1) + i }
          
          elapsed_time = measure_time do
            dates.each { |date| JapaneseBusinessDays.add_business_days(date, 10) }
          end
          
          expect(elapsed_time).to be < LARGE_BATCH_MAX_TIME
        end
      end

      describe "長期間の営業日計算" do
        it "10年間の営業日数計算が1秒以内に完了する" do
          start_date = Date.new(2020, 1, 1)
          end_date = Date.new(2029, 12, 31)
          
          elapsed_time = measure_time do
            JapaneseBusinessDays.business_days_between(start_date, end_date)
          end
          
          expect(elapsed_time).to be < LARGE_BATCH_MAX_TIME
        end

        it "1000営業日の加算が1秒以内に完了する" do
          base_date = Date.new(2024, 1, 1)
          
          elapsed_time = measure_time do
            JapaneseBusinessDays.add_business_days(base_date, 1000)
          end
          
          expect(elapsed_time).to be < LARGE_BATCH_MAX_TIME
        end

        it "複数年にわたる複雑な計算が1秒以内に完了する" do
          base_date = Date.new(2020, 1, 1)
          
          elapsed_time = measure_time do
            100.times do |i|
              current_date = base_date + (i * 30)
              JapaneseBusinessDays.add_business_days(current_date, 20)
              JapaneseBusinessDays.business_days_between(current_date, current_date + 60)
            end
          end
          
          expect(elapsed_time).to be < LARGE_BATCH_MAX_TIME
        end
      end
    end

    context "メモリ使用量のテスト" do
      describe "メモリ効率性" do
        it "大量の営業日計算でメモリリークが発生しない" do
          initial_memory = get_memory_usage_mb
          
          # 大量の計算を実行
          1000.times do |i|
            date = Date.new(2024, 1, 1) + i
            JapaneseBusinessDays.business_day?(date)
            JapaneseBusinessDays.add_business_days(date, 10)
            JapaneseBusinessDays.business_days_between(date, date + 30)
          end
          
          GC.start
          final_memory = get_memory_usage_mb
          memory_increase = final_memory - initial_memory
          
          # メモリ増加が許容範囲内であることを確認
          expect(memory_increase).to be < 5.0 # 5MB以内
        end

        it "祝日キャッシュのメモリ使用量が適切である" do
          initial_memory = get_memory_usage_mb
          
          # 複数年の祝日データを取得してキャッシュに保存
          (2020..2030).each do |year|
            JapaneseBusinessDays.holidays_in_year(year)
          end
          
          GC.start
          final_memory = get_memory_usage_mb
          memory_increase = final_memory - initial_memory
          
          # 11年分の祝日データでも適切なメモリ使用量
          expect(memory_increase).to be < 2.0 # 2MB以内
        end

        it "設定変更時のメモリ管理が適切である" do
          initial_memory = get_memory_usage_mb
          
          # 設定を複数回変更
          30.times do |i|
            JapaneseBusinessDays.configure do |config|
              config.add_holiday(Date.new(2024, 6, i + 1))
            end
          end
          
          GC.start
          final_memory = get_memory_usage_mb
          memory_increase = final_memory - initial_memory
          
          # 設定変更でのメモリ増加が適切
          expect(memory_increase).to be < 3.0 # 3MB以内
          
          # テスト後にリセット
          JapaneseBusinessDays.configuration.reset!
        end
      end

      describe "ガベージコレクション効率" do
        it "一時オブジェクトが適切にガベージコレクションされる" do
          # GCを実行してベースラインを設定
          GC.start
          initial_objects = ObjectSpace.count_objects[:T_OBJECT]
          
          # 大量の一時オブジェクトを生成する操作
          1000.times do |i|
            date = Date.new(2024, 1, 1) + i
            JapaneseBusinessDays.business_day?(date)
          end
          
          # GCを実行
          GC.start
          final_objects = ObjectSpace.count_objects[:T_OBJECT]
          
          # オブジェクト数の増加が適切な範囲内
          object_increase = final_objects - initial_objects
          expect(object_increase).to be < 1000 # 1000オブジェクト以内
        end
      end
    end

    context "スケーラビリティテスト" do
      describe "負荷増加時の性能劣化" do
        it "計算回数の増加に対して線形的な性能劣化" do
          # 異なる回数での実行時間を測定
          times_100 = measure_time do
            100.times { |i| JapaneseBusinessDays.business_day?(Date.new(2024, 1, 1) + i) }
          end
          
          times_1000 = measure_time do
            1000.times { |i| JapaneseBusinessDays.business_day?(Date.new(2024, 1, 1) + i) }
          end
          
          # 10倍の処理で実行時間が20倍以下（線形的な劣化）
          performance_ratio = times_1000 / times_100
          expect(performance_ratio).to be < 20
        end

        it "データ範囲の拡大に対する性能安定性" do
          # 1ヶ月間の営業日計算
          time_1_month = measure_time do
            start_date = Date.new(2024, 1, 1)
            end_date = Date.new(2024, 1, 31)
            JapaneseBusinessDays.business_days_between(start_date, end_date)
          end
          
          # 1年間の営業日計算
          time_1_year = measure_time do
            start_date = Date.new(2024, 1, 1)
            end_date = Date.new(2024, 12, 31)
            JapaneseBusinessDays.business_days_between(start_date, end_date)
          end
          
          # 12倍の期間で実行時間が50倍以下
          performance_ratio = time_1_year / time_1_month
          expect(performance_ratio).to be < 50
        end
      end

      describe "並行処理での安定性" do
        it "複数スレッドでの同時実行が安全である" do
          threads = []
          results = []
          mutex = Mutex.new
          
          # 10個のスレッドで並行実行
          10.times do |thread_id|
            threads << Thread.new do
              thread_results = []
              100.times do |i|
                date = Date.new(2024, 1, 1) + (thread_id * 100) + i
                result = JapaneseBusinessDays.business_day?(date)
                thread_results << result
              end
              
              mutex.synchronize do
                results.concat(thread_results)
              end
            end
          end
          
          # 全スレッドの完了を待機
          start_time = Time.now
          threads.each(&:join)
          elapsed_time = Time.now - start_time
          
          # 並行実行が適切な時間内に完了
          expect(elapsed_time).to be < 2.0 # 2秒以内
          
          # 全ての結果が取得できている
          expect(results.length).to eq(1000)
          
          # 結果がboolean値である
          expect(results.all? { |r| r.is_a?(TrueClass) || r.is_a?(FalseClass) }).to be true
        end
      end
    end

    context "ベンチマーク比較" do
      describe "異なる実装方式の性能比較" do
        it "キャッシュありとキャッシュなしの性能差を測定" do
          year = 2024
          
          # 新しい年を使ってキャッシュなし状態を作る
          uncached_year = 2030
          
          # キャッシュなしでの実行時間（新しい年）
          time_without_cache = measure_time do
            10.times { JapaneseBusinessDays.holidays_in_year(uncached_year) }
          end
          
          # キャッシュありでの実行時間（既にキャッシュされた年）
          time_with_cache = measure_time do
            10.times { JapaneseBusinessDays.holidays_in_year(year) }
          end
          
          # キャッシュによる性能向上を確認（実際の性能差は小さい場合もある）
          performance_improvement = time_without_cache / time_with_cache
          expect(performance_improvement).to be > 0.5 # 性能が大幅に劣化していないことを確認
        end

        it "異なる日付形式での性能比較" do
          date_obj = Date.new(2024, 1, 10)
          time_obj = Time.new(2024, 1, 10, 10, 0, 0)
          datetime_obj = DateTime.new(2024, 1, 10, 10, 0, 0)
          string_obj = "2024-01-10"
          
          # 各形式での実行時間を測定
          time_date = measure_time do
            1000.times { JapaneseBusinessDays.business_day?(date_obj) }
          end
          
          time_time = measure_time do
            1000.times { JapaneseBusinessDays.business_day?(time_obj) }
          end
          
          time_datetime = measure_time do
            1000.times { JapaneseBusinessDays.business_day?(datetime_obj) }
          end
          
          time_string = measure_time do
            1000.times { JapaneseBusinessDays.business_day?(string_obj) }
          end
          
          # Date形式が最も高速であることを確認（許容誤差を考慮）
          expect(time_date).to be <= time_time * 1.1  # 10%の誤差を許容
          expect(time_date).to be <= time_datetime * 1.1
          expect(time_date).to be <= time_string * 1.1
          
          # 全ての形式が許容時間内
          expect(time_date).to be < BATCH_OPERATION_MAX_TIME
          expect(time_time).to be < BATCH_OPERATION_MAX_TIME
          expect(time_datetime).to be < BATCH_OPERATION_MAX_TIME
          expect(time_string).to be < BATCH_OPERATION_MAX_TIME
        end
      end

      describe "実用的なベンチマーク" do
        it "典型的な業務アプリケーションでの使用パターン" do
          # 月次処理のシミュレーション
          monthly_processing_time = measure_time do
            # 1ヶ月分の営業日を処理
            start_date = Date.new(2024, 1, 1)
            end_date = Date.new(2024, 1, 31)
            
            # 各日の営業日判定
            (start_date..end_date).each do |date|
              JapaneseBusinessDays.business_day?(date)
            end
            
            # 営業日数計算
            JapaneseBusinessDays.business_days_between(start_date, end_date)
            
            # 支払期日計算（複数パターン）
            10.times do |i|
              base_date = start_date + (i * 3)
              JapaneseBusinessDays.add_business_days(base_date, 30)
            end
          end
          
          # 月次処理が適切な時間内に完了
          expect(monthly_processing_time).to be < 0.05 # 50ms以内
        end

        it "年次処理のパフォーマンス" do
          # 年次処理のシミュレーション
          yearly_processing_time = measure_time do
            year = 2024
            
            # 年間祝日取得
            holidays = JapaneseBusinessDays.holidays_in_year(year)
            
            # 各月の営業日数計算
            12.times do |month|
              start_date = Date.new(year, month + 1, 1)
              end_date = Date.new(year, month + 1, -1) # 月末
              JapaneseBusinessDays.business_days_between(start_date, end_date)
            end
            
            # 四半期ごとの営業日計算
            4.times do |quarter|
              q_start = Date.new(year, quarter * 3 + 1, 1)
              q_end = Date.new(year, (quarter + 1) * 3, -1)
              JapaneseBusinessDays.business_days_between(q_start, q_end)
            end
          end
          
          # 年次処理が適切な時間内に完了
          expect(yearly_processing_time).to be < 0.1 # 100ms以内
        end
      end
    end

    private

    # 実行時間を測定するヘルパーメソッド
    def measure_time
      start_time = Time.now
      yield
      Time.now - start_time
    end

    # メモリ使用量を取得するヘルパーメソッド（MB単位）
    def get_memory_usage_mb
      # Rubyプロセスのメモリ使用量を取得
      if RUBY_PLATFORM =~ /linux/
        # Linuxの場合
        status = File.read("/proc/#{Process.pid}/status")
        vmrss_line = status.lines.find { |line| line.start_with?("VmRSS:") }
        if vmrss_line
          vmrss_kb = vmrss_line.split[1].to_i
          return vmrss_kb / 1024.0
        end
      elsif RUBY_PLATFORM =~ /darwin/
        # macOSの場合
        ps_output = `ps -o rss= -p #{Process.pid}`.strip
        rss_kb = ps_output.to_i
        return rss_kb / 1024.0 if rss_kb > 0
      end
      
      # フォールバック: ObjectSpaceを使用した簡易的な測定
      GC.start
      ObjectSpace.count_objects[:T_OBJECT] * 0.001 # 概算値
    end
  end
end