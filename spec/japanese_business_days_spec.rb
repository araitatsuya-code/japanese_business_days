# frozen_string_literal: true

RSpec.describe JapaneseBusinessDays do
  it "has a version number" do
    expect(JapaneseBusinessDays::VERSION).not_to be_nil
  end

  it "loads core interfaces successfully" do
    expect(JapaneseBusinessDays::Configuration).to be_a(Class)
    expect(JapaneseBusinessDays::Holiday).to be_a(Class)
    expect(JapaneseBusinessDays::HolidayCalculator).to be_a(Class)
    expect(JapaneseBusinessDays::BusinessDayCalculator).to be_a(Class)
  end

  describe "公開API" do
    describe ".business_days_between" do
      context "要件1.1: 営業日数計算" do
        it "平日のみの期間で正しい営業日数を返す" do
          # 2024年1月9日(火) から 2024年1月12日(金) まで = 3営業日
          start_date = Date.new(2024, 1, 9)
          end_date = Date.new(2024, 1, 12)
          expect(JapaneseBusinessDays.business_days_between(start_date, end_date)).to eq(3)
        end

        it "土日を含む期間で正しい営業日数を返す" do
          # 2024年1月8日(月) から 2024年1月15日(月) まで = 5営業日
          start_date = Date.new(2024, 1, 8)
          end_date = Date.new(2024, 1, 15)
          expect(JapaneseBusinessDays.business_days_between(start_date, end_date)).to eq(5)
        end

        it "祝日を含む期間で正しい営業日数を返す" do
          # 2024年1月1日(月・元日) から 2024年1月5日(金) まで = 4営業日
          start_date = Date.new(2024, 1, 1)
          end_date = Date.new(2024, 1, 5)
          expect(JapaneseBusinessDays.business_days_between(start_date, end_date)).to eq(4)
        end
      end

      context "要件1.2: 異なる日付形式の受け入れ" do
        it "Time形式の日付を受け入れる" do
          start_time = Time.new(2024, 1, 9, 10, 0, 0)
          end_time = Time.new(2024, 1, 12, 15, 30, 0)
          expect(JapaneseBusinessDays.business_days_between(start_time, end_time)).to eq(3)
        end

        it "DateTime形式の日付を受け入れる" do
          start_datetime = DateTime.new(2024, 1, 9, 10, 0, 0)
          end_datetime = DateTime.new(2024, 1, 12, 15, 30, 0)
          expect(JapaneseBusinessDays.business_days_between(start_datetime, end_datetime)).to eq(3)
        end

        it "String形式の日付を受け入れる" do
          expect(JapaneseBusinessDays.business_days_between("2024-01-09", "2024-01-12")).to eq(3)
        end
      end

      context "要件1.3: 逆方向の計算" do
        it "開始日が終了日より後の場合、負の数を返す" do
          start_date = Date.new(2024, 1, 12)
          end_date = Date.new(2024, 1, 9)
          expect(JapaneseBusinessDays.business_days_between(start_date, end_date)).to eq(-3)
        end
      end

      context "要件1.4: 同じ日付の処理" do
        it "開始日と終了日が同じ場合、0を返す" do
          date = Date.new(2024, 1, 10)
          expect(JapaneseBusinessDays.business_days_between(date, date)).to eq(0)
        end
      end
    end

    describe ".business_day?" do
      context "要件3.1: 営業日判定" do
        it "平日かつ祝日でない場合にtrueを返す" do
          # 2024年1月10日(水)
          date = Date.new(2024, 1, 10)
          expect(JapaneseBusinessDays.business_day?(date)).to be true
        end

        it "土曜日の場合にfalseを返す" do
          # 2024年1月6日(土)
          date = Date.new(2024, 1, 6)
          expect(JapaneseBusinessDays.business_day?(date)).to be false
        end

        it "日曜日の場合にfalseを返す" do
          # 2024年1月7日(日)
          date = Date.new(2024, 1, 7)
          expect(JapaneseBusinessDays.business_day?(date)).to be false
        end

        it "祝日の場合にfalseを返す" do
          # 2024年1月1日(月・元日)
          date = Date.new(2024, 1, 1)
          expect(JapaneseBusinessDays.business_day?(date)).to be false
        end

        it "振替休日の場合にfalseを返す" do
          # 2023年1月2日(月・振替休日) - 元日が日曜日だった年
          date = Date.new(2023, 1, 2)
          expect(JapaneseBusinessDays.business_day?(date)).to be false
        end
      end
    end

    describe ".holiday?" do
      context "要件4.1: 祝日判定" do
        it "日本の祝日の場合にtrueを返す" do
          # 元日
          expect(JapaneseBusinessDays.holiday?(Date.new(2024, 1, 1))).to be true
          # 建国記念の日
          expect(JapaneseBusinessDays.holiday?(Date.new(2024, 2, 11))).to be true
          # 成人の日（ハッピーマンデー）
          expect(JapaneseBusinessDays.holiday?(Date.new(2024, 1, 8))).to be true
        end

        it "祝日でない場合にfalseを返す" do
          # 2024年1月10日(水)
          expect(JapaneseBusinessDays.holiday?(Date.new(2024, 1, 10))).to be false
        end

        it "振替休日を正しく処理する" do
          # 2023年1月2日(月・振替休日) - 元日が日曜日だった年
          expect(JapaneseBusinessDays.holiday?(Date.new(2023, 1, 2))).to be true
        end
      end
    end

    describe ".holidays_in_year" do
      context "要件4.2: 年間祝日取得" do
        it "指定年のすべての日本の祝日を返す" do
          holidays = JapaneseBusinessDays.holidays_in_year(2024)

          expect(holidays).to be_an(Array)
          expect(holidays).not_to be_empty

          # 固定祝日の確認
          holiday_dates = holidays.map(&:date)
          expect(holiday_dates).to include(Date.new(2024, 1, 1))   # 元日
          expect(holiday_dates).to include(Date.new(2024, 2, 11))  # 建国記念の日
          expect(holiday_dates).to include(Date.new(2024, 4, 29))  # 昭和の日

          # ハッピーマンデー祝日の確認
          expect(holiday_dates).to include(Date.new(2024, 1, 8))   # 成人の日
          expect(holiday_dates).to include(Date.new(2024, 7, 15))  # 海の日

          # 計算祝日の確認（春分の日・秋分の日）
          expect(holiday_dates.any? { |d| d.month == 3 && d.day.between?(19, 22) }).to be true
          expect(holiday_dates.any? { |d| d.month == 9 && d.day.between?(21, 24) }).to be true
        end

        it "祝日が日付順にソートされている" do
          holidays = JapaneseBusinessDays.holidays_in_year(2024)
          dates = holidays.map(&:date)
          expect(dates).to eq(dates.sort)
        end

        it "各祝日にHolidayオブジェクトが含まれている" do
          holidays = JapaneseBusinessDays.holidays_in_year(2024)
          holidays.each do |holiday|
            expect(holiday).to be_a(JapaneseBusinessDays::Holiday)
            expect(holiday.date).to be_a(Date)
            expect(holiday.name).to be_a(String)
            expect(holiday.type).to be_a(Symbol)
          end
        end
      end
    end

    describe ".configure" do
      context "要件5.1-5.4: カスタムビジネスルール設定" do
        after do
          # テスト後に設定をリセット
          JapaneseBusinessDays.configuration.reset!
        end

        it "設定ブロックを受け取り、Configurationオブジェクトを渡す" do
          config_received = nil
          JapaneseBusinessDays.configure do |config|
            config_received = config
          end

          expect(config_received).to be_a(JapaneseBusinessDays::Configuration)
          expect(config_received).to eq(JapaneseBusinessDays.configuration)
        end

        it "カスタム非営業日を設定できる" do
          custom_holiday = Date.new(2024, 12, 31)

          JapaneseBusinessDays.configure do |config|
            config.add_holiday(custom_holiday)
          end

          expect(JapaneseBusinessDays.business_day?(custom_holiday)).to be false
        end

        it "カスタム営業日を設定できる" do
          # 元日を営業日として上書き
          new_years_day = Date.new(2024, 1, 1)

          JapaneseBusinessDays.configure do |config|
            config.add_business_day(new_years_day)
          end

          expect(JapaneseBusinessDays.business_day?(new_years_day)).to be true
        end

        it "週末の定義を変更できる" do
          # 金曜日と土曜日を週末に設定
          JapaneseBusinessDays.configure do |config|
            config.weekend_days = [5, 6]
          end

          # 金曜日が非営業日になる
          friday = Date.new(2024, 1, 12) # 金曜日
          expect(JapaneseBusinessDays.business_day?(friday)).to be false

          # 日曜日が営業日になる
          sunday = Date.new(2024, 1, 14) # 日曜日
          expect(JapaneseBusinessDays.business_day?(sunday)).to be true
        end
      end
    end

    describe ".configuration" do
      it "Configurationオブジェクトを返す" do
        config = JapaneseBusinessDays.configuration
        expect(config).to be_a(JapaneseBusinessDays::Configuration)
      end

      it "同じインスタンスを返す（シングルトン）" do
        config1 = JapaneseBusinessDays.configuration
        config2 = JapaneseBusinessDays.configuration
        expect(config1).to be(config2)
      end
    end

    describe ".add_business_days" do
      context "要件2.1: 営業日加算" do
        it "指定日からn営業日後の新しい日付を返す" do
          # 2024年1月9日(火) + 3営業日 = 2024年1月12日(金)
          base_date = Date.new(2024, 1, 9)
          result = JapaneseBusinessDays.add_business_days(base_date, 3)
          expect(result).to eq(Date.new(2024, 1, 12))
        end

        it "土日や祝日をスキップする" do
          # 2024年1月5日(金) + 1営業日 = 2024年1月9日(火) (土日と元日をスキップ)
          base_date = Date.new(2024, 1, 5)
          result = JapaneseBusinessDays.add_business_days(base_date, 1)
          expect(result).to eq(Date.new(2024, 1, 9))
        end

        it "nが0の場合、営業日であればその日付を返す" do
          # 2024年1月10日(水) + 0営業日 = 2024年1月10日(水)
          base_date = Date.new(2024, 1, 10)
          result = JapaneseBusinessDays.add_business_days(base_date, 0)
          expect(result).to eq(base_date)
        end

        it "nが0で非営業日の場合、次の営業日を返す" do
          # 2024年1月6日(土) + 0営業日 = 2024年1月9日(火) (日曜日と元日をスキップ)
          base_date = Date.new(2024, 1, 6)
          result = JapaneseBusinessDays.add_business_days(base_date, 0)
          expect(result).to eq(Date.new(2024, 1, 9))
        end

        it "異なる日付形式を受け入れる" do
          # Time形式
          base_time = Time.new(2024, 1, 9, 10, 0, 0)
          result = JapaneseBusinessDays.add_business_days(base_time, 1)
          expect(result).to eq(Date.new(2024, 1, 10))

          # String形式
          result = JapaneseBusinessDays.add_business_days("2024-01-09", 1)
          expect(result).to eq(Date.new(2024, 1, 10))
        end
      end
    end

    describe ".subtract_business_days" do
      context "要件2.2: 営業日減算" do
        it "指定日からn営業日前の新しい日付を返す" do
          # 2024年1月12日(金) - 3営業日 = 2024年1月9日(火)
          base_date = Date.new(2024, 1, 12)
          result = JapaneseBusinessDays.subtract_business_days(base_date, 3)
          expect(result).to eq(Date.new(2024, 1, 9))
        end

        it "土日や祝日をスキップする" do
          # 2024年1月9日(火) - 1営業日 = 2024年1月5日(金) (土日と元日をスキップ)
          base_date = Date.new(2024, 1, 9)
          result = JapaneseBusinessDays.subtract_business_days(base_date, 1)
          expect(result).to eq(Date.new(2024, 1, 5))
        end

        it "異なる日付形式を受け入れる" do
          # DateTime形式
          base_datetime = DateTime.new(2024, 1, 12, 15, 30, 0)
          result = JapaneseBusinessDays.subtract_business_days(base_datetime, 1)
          expect(result).to eq(Date.new(2024, 1, 11))

          # String形式
          result = JapaneseBusinessDays.subtract_business_days("2024-01-12", 1)
          expect(result).to eq(Date.new(2024, 1, 11))
        end
      end
    end

    describe ".next_business_day" do
      context "要件2.4: 次の営業日検索" do
        it "次の営業日を返す" do
          # 2024年1月5日(金)の次の営業日 = 2024年1月9日(火) (土日と元日をスキップ)
          base_date = Date.new(2024, 1, 5)
          result = JapaneseBusinessDays.next_business_day(base_date)
          expect(result).to eq(Date.new(2024, 1, 9))
        end

        it "平日の次の営業日を返す" do
          # 2024年1月9日(火)の次の営業日 = 2024年1月10日(水)
          base_date = Date.new(2024, 1, 9)
          result = JapaneseBusinessDays.next_business_day(base_date)
          expect(result).to eq(Date.new(2024, 1, 10))
        end
      end
    end

    describe ".previous_business_day" do
      context "要件2.4: 前の営業日検索" do
        it "前の営業日を返す" do
          # 2024年1月9日(火)の前の営業日 = 2024年1月5日(金) (土日と元日をスキップ)
          base_date = Date.new(2024, 1, 9)
          result = JapaneseBusinessDays.previous_business_day(base_date)
          expect(result).to eq(Date.new(2024, 1, 5))
        end

        it "平日の前の営業日を返す" do
          # 2024年1月11日(木)の前の営業日 = 2024年1月10日(水)
          base_date = Date.new(2024, 1, 11)
          result = JapaneseBusinessDays.previous_business_day(base_date)
          expect(result).to eq(Date.new(2024, 1, 10))
        end
      end
    end

    describe "エラーハンドリング" do
      context "要件8.1-8.2: 入力検証とエラーメッセージ" do
        it "無効な日付形式でInvalidDateErrorを発生させる" do
          expect do
            JapaneseBusinessDays.business_days_between("invalid-date", Date.today)
          end.to raise_error(JapaneseBusinessDays::InvalidDateError)
        end

        it "nilが渡された場合にInvalidArgumentErrorを発生させる" do
          expect do
            JapaneseBusinessDays.business_day?(nil)
          end.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
        end

        it "無効な引数タイプでInvalidArgumentErrorを発生させる" do
          expect do
            JapaneseBusinessDays.holiday?(123)
          end.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
        end

        it "無効な年でInvalidArgumentErrorを発生させる" do
          expect do
            JapaneseBusinessDays.holidays_in_year("2024")
          end.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
        end
      end
    end

    describe "内部コンポーネントとの連携" do
      it "HolidayCalculatorと正しく連携する" do
        # 祝日計算が正しく動作することを確認
        expect(JapaneseBusinessDays.holiday?(Date.new(2024, 1, 1))).to be true
        expect(JapaneseBusinessDays.holiday?(Date.new(2024, 1, 10))).to be false
      end

      it "BusinessDayCalculatorと正しく連携する" do
        # 営業日計算が正しく動作することを確認
        start_date = Date.new(2024, 1, 9)
        end_date = Date.new(2024, 1, 12)
        expect(JapaneseBusinessDays.business_days_between(start_date, end_date)).to eq(3)
      end

      it "Configurationと正しく連携する" do
        # 設定変更が営業日計算に反映されることを確認
        custom_holiday = Date.new(2024, 1, 10)

        JapaneseBusinessDays.configure do |config|
          config.add_holiday(custom_holiday)
        end

        expect(JapaneseBusinessDays.business_day?(custom_holiday)).to be false

        # テスト後にリセット
        JapaneseBusinessDays.configuration.reset!
      end
    end

    describe "パフォーマンス" do
      context "要件6.1-6.4: 高度な最適化" do
        it "大量の営業日計算を効率的に処理する" do
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

        it "祝日データのキャッシュが機能する" do
          # 同じ年の祝日を複数回取得してもパフォーマンスが劣化しない
          start_time = Time.now

          10.times do
            JapaneseBusinessDays.holidays_in_year(2024)
          end

          elapsed_time = Time.now - start_time
          expect(elapsed_time).to be < 0.1 # 100ms以内に完了
        end
      end
    end
  end
end
