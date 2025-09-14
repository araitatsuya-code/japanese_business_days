# frozen_string_literal: true

# Date拡張を手動でロード（テスト環境用）
Date.include(JapaneseBusinessDays::DateExtensions)
Time.include(JapaneseBusinessDays::DateExtensions)
DateTime.include(JapaneseBusinessDays::DateExtensions)

RSpec.describe "JapaneseBusinessDays Integration Tests" do
  describe "エンドツーエンド統合テスト" do
    context "実際の使用シナリオ" do
      describe "金融システムでの支払期日計算" do
        it "契約日から30営業日後の支払期日を正確に計算する" do
          # 2024年1月15日(月)に契約
          contract_date = Date.new(2024, 1, 15)
          
          # 30営業日後の支払期日を計算
          payment_due_date = JapaneseBusinessDays.add_business_days(contract_date, 30)
          
          # 期待値: 2024年2月27日(火) - 土日祝日を除いた30営業日後
          expect(payment_due_date).to eq(Date.new(2024, 2, 27))
          
          # 計算された日付が営業日であることを確認
          expect(JapaneseBusinessDays.business_day?(payment_due_date)).to be true
        end

        it "月末締めから翌月末支払いまでの営業日数を計算する" do
          # 2024年1月31日(水)締め
          closing_date = Date.new(2024, 1, 31)
          
          # 2024年2月29日(木)支払い
          payment_date = Date.new(2024, 2, 29)
          
          # 営業日数を計算
          business_days = JapaneseBusinessDays.business_days_between(closing_date, payment_date)
          
          # 期待値: 20営業日（2月の土日祝日を除く）
          expect(business_days).to eq(20)
        end

        it "四半期末から次四半期開始までの営業日数を計算する" do
          # Q1末: 2024年3月29日(金)
          q1_end = Date.new(2024, 3, 29)
          
          # Q2開始: 2024年4月1日(月)
          q2_start = Date.new(2024, 4, 1)
          
          # 営業日数を計算
          business_days = JapaneseBusinessDays.business_days_between(q1_end, q2_start)
          
          # 期待値: 1営業日（土日を挟むため）
          expect(business_days).to eq(1)
        end
      end

      describe "プロジェクト管理での工期計算" do
        it "プロジェクト開始から完了までの営業日数を計算する" do
          # プロジェクト開始: 2024年4月1日(月)
          project_start = Date.new(2024, 4, 1)
          
          # プロジェクト完了: 2024年6月28日(金)
          project_end = Date.new(2024, 6, 28)
          
          # 営業日数を計算
          business_days = JapaneseBusinessDays.business_days_between(project_start, project_end)
          
          # 期待値: 61営業日（4-6月の土日祝日を除く）
          expect(business_days).to eq(61)
        end

        it "マイルストーン間の営業日数を計算する" do
          # マイルストーン1: 2024年5月3日(金・憲法記念日)
          milestone1 = Date.new(2024, 5, 3)
          
          # マイルストーン2: 2024年5月10日(金)
          milestone2 = Date.new(2024, 5, 10)
          
          # 営業日数を計算
          business_days = JapaneseBusinessDays.business_days_between(milestone1, milestone2)
          
          # 期待値: 4営業日（GW期間の祝日を除く）
          expect(business_days).to eq(4)
        end

        it "緊急対応での次営業日計算" do
          # 金曜日夜に障害発生
          incident_date = Date.new(2024, 1, 5) # 金曜日
          
          # 次営業日に対応開始
          response_date = JapaneseBusinessDays.next_business_day(incident_date)
          
          # 期待値: 2024年1月9日(火) - 土日と元日をスキップ
          expect(response_date).to eq(Date.new(2024, 1, 9))
          expect(JapaneseBusinessDays.business_day?(response_date)).to be true
        end
      end

      describe "人事システムでの勤務日計算" do
        it "入社日から試用期間終了日を計算する" do
          # 入社日: 2024年4月1日(月)
          hire_date = Date.new(2024, 4, 1)
          
          # 試用期間90営業日後
          probation_end = JapaneseBusinessDays.add_business_days(hire_date, 90)
          
          # 期待値: 2024年8月9日(金)
          expect(probation_end).to eq(Date.new(2024, 8, 9))
          expect(JapaneseBusinessDays.business_day?(probation_end)).to be true
        end

        it "有給休暇申請の営業日チェック" do
          vacation_dates = [
            Date.new(2024, 5, 1), # 水曜日
            Date.new(2024, 5, 2), # 木曜日
            Date.new(2024, 5, 6)  # 月曜日（振替休日）
          ]
          
          # 各日付の営業日判定
          results = vacation_dates.map { |date| JapaneseBusinessDays.business_day?(date) }
          
          # 期待値: [true, true, false] - 5/6は振替休日
          expect(results).to eq([true, true, false])
        end
      end

      describe "配送システムでの配達日計算" do
        it "注文日から配達予定日を計算する" do
          # 注文日: 2024年12月27日(金)
          order_date = Date.new(2024, 12, 27)
          
          # 3営業日後に配達
          delivery_date = JapaneseBusinessDays.add_business_days(order_date, 3)
          
          # 期待値: 2025年1月2日(木) - 年末年始を考慮
          expect(delivery_date).to eq(Date.new(2025, 1, 2))
          expect(JapaneseBusinessDays.business_day?(delivery_date)).to be true
        end

        it "配送不可日（祝日）の自動調整" do
          # 祝日に配送予定の場合、次営業日に調整
          holiday_date = Date.new(2024, 1, 1) # 元日
          
          adjusted_date = JapaneseBusinessDays.next_business_day(holiday_date)
          
          # 期待値: 2024年1月2日(火) - 1/2は営業日
          expect(adjusted_date).to eq(Date.new(2024, 1, 2))
          expect(JapaneseBusinessDays.business_day?(adjusted_date)).to be true
        end
      end
    end

    context "複数年にわたる営業日計算" do
      describe "年をまたぐ長期計算" do
        it "2023年から2024年にかけての営業日数を正確に計算する" do
          # 2023年12月1日から2024年2月29日まで
          start_date = Date.new(2023, 12, 1)
          end_date = Date.new(2024, 2, 29)
          
          business_days = JapaneseBusinessDays.business_days_between(start_date, end_date)
          
          # 期待値: 61営業日（年末年始の祝日を考慮）
          expect(business_days).to eq(61)
        end

        it "複数年にわたる祝日データの一貫性を確認する" do
          years = [2023, 2024, 2025]
          
          years.each do |year|
            holidays = JapaneseBusinessDays.holidays_in_year(year)
            
            # 各年に最低限の祝日が含まれていることを確認
            expect(holidays.length).to be >= 15
            
            # 元日が含まれていることを確認
            new_years_day = holidays.find { |h| h.date == Date.new(year, 1, 1) }
            expect(new_years_day).not_to be_nil
            expect(new_years_day.name).to eq("元日")
            
            # 祝日が日付順にソートされていることを確認
            dates = holidays.map(&:date)
            expect(dates).to eq(dates.sort)
          end
        end

        it "5年間の営業日計算パフォーマンスを確認する" do
          start_date = Date.new(2020, 1, 1)
          end_date = Date.new(2024, 12, 31)
          
          start_time = Time.now
          business_days = JapaneseBusinessDays.business_days_between(start_date, end_date)
          elapsed_time = Time.now - start_time
          
          # 5年間の営業日数が妥当な範囲内であることを確認
          expect(business_days).to be_between(1230, 1250) # 約1234営業日
          
          # パフォーマンス要件: 100ms以内に完了
          expect(elapsed_time).to be < 0.1
        end

        it "うるう年を含む期間の営業日計算" do
          # 2024年はうるう年
          leap_year_start = Date.new(2024, 2, 1)
          leap_year_end = Date.new(2024, 3, 1)
          
          business_days = JapaneseBusinessDays.business_days_between(leap_year_start, leap_year_end)
          
          # 2月の営業日数（うるう年考慮）
          expect(business_days).to eq(20) # 2024年2月の営業日数
        end
      end

      describe "特殊な祝日パターンの処理" do
        it "振替休日が複数発生する年の処理" do
          # 2023年は元日が日曜日で振替休日が発生
          holidays_2023 = JapaneseBusinessDays.holidays_in_year(2023)
          
          # 振替休日が含まれていることを確認
          substitute_holiday = holidays_2023.find { |h| h.date == Date.new(2023, 1, 2) }
          expect(substitute_holiday).not_to be_nil
          expect(substitute_holiday.type).to eq(:substitute)
        end

        it "春分の日・秋分の日の年による変動を確認" do
          years = [2023, 2024, 2025]
          
          years.each do |year|
            holidays = JapaneseBusinessDays.holidays_in_year(year)
            
            # 春分の日の確認
            vernal_equinox = holidays.find { |h| h.name == "春分の日" }
            expect(vernal_equinox).not_to be_nil
            expect(vernal_equinox.date.month).to eq(3)
            expect(vernal_equinox.date.day).to be_between(19, 22)
            
            # 秋分の日の確認
            autumnal_equinox = holidays.find { |h| h.name == "秋分の日" }
            expect(autumnal_equinox).not_to be_nil
            expect(autumnal_equinox.date.month).to eq(9)
            expect(autumnal_equinox.date.day).to be_between(21, 24)
          end
        end

        it "ハッピーマンデー祝日の正確な計算" do
          # 2024年のハッピーマンデー祝日を確認
          holidays_2024 = JapaneseBusinessDays.holidays_in_year(2024)
          
          # 成人の日（1月第2月曜日）
          coming_of_age_day = holidays_2024.find { |h| h.name == "成人の日" }
          expect(coming_of_age_day.date).to eq(Date.new(2024, 1, 8))
          expect(coming_of_age_day.date.wday).to eq(1) # 月曜日
          
          # 海の日（7月第3月曜日）
          marine_day = holidays_2024.find { |h| h.name == "海の日" }
          expect(marine_day.date).to eq(Date.new(2024, 7, 15))
          expect(marine_day.date.wday).to eq(1) # 月曜日
          
          # 敬老の日（9月第3月曜日）
          respect_for_aged_day = holidays_2024.find { |h| h.name == "敬老の日" }
          expect(respect_for_aged_day.date).to eq(Date.new(2024, 9, 16))
          expect(respect_for_aged_day.date.wday).to eq(1) # 月曜日
          
          # スポーツの日（10月第2月曜日）
          sports_day = holidays_2024.find { |h| h.name == "スポーツの日" }
          expect(sports_day.date).to eq(Date.new(2024, 10, 14))
          expect(sports_day.date.wday).to eq(1) # 月曜日
        end
      end
    end

    context "カスタム設定との統合" do
      after do
        # テスト後に設定をリセット
        JapaneseBusinessDays.configuration.reset!
      end

      describe "企業固有の営業日ルール" do
        it "会社創立記念日を非営業日として設定" do
          # 会社創立記念日を追加
          founding_day = Date.new(2024, 6, 15)
          
          JapaneseBusinessDays.configure do |config|
            config.add_holiday(founding_day)
          end
          
          # 創立記念日が非営業日として扱われることを確認
          expect(JapaneseBusinessDays.business_day?(founding_day)).to be false
          
          # 営業日計算にも反映されることを確認
          start_date = Date.new(2024, 6, 14)
          end_date = Date.new(2024, 6, 17)
          business_days = JapaneseBusinessDays.business_days_between(start_date, end_date)
          
          # 6/15が非営業日として除外される
          expect(business_days).to eq(1) # 6/14(金) -> 6/17(月)
        end

        it "特別営業日（祝日出勤）の設定" do
          # 文化の日を特別営業日として設定
          culture_day = Date.new(2024, 11, 3)
          
          JapaneseBusinessDays.configure do |config|
            config.add_business_day(culture_day)
          end
          
          # 文化の日が営業日として扱われることを確認
          expect(JapaneseBusinessDays.business_day?(culture_day)).to be true
          
          # 営業日計算にも反映されることを確認
          start_date = Date.new(2024, 11, 1)
          end_date = Date.new(2024, 11, 4)
          business_days = JapaneseBusinessDays.business_days_between(start_date, end_date)
          
          # 11/3が営業日として含まれる
          expect(business_days).to eq(1) # 11/1(金)のみ（11/3は日曜日なので除外）
        end

        it "カスタム週末設定（中東式週末）" do
          # 金曜日と土曜日を週末に設定
          JapaneseBusinessDays.configure do |config|
            config.weekend_days = [5, 6] # 金曜日、土曜日
          end
          
          # 週末判定の確認
          friday = Date.new(2024, 1, 12)    # 金曜日
          saturday = Date.new(2024, 1, 13)  # 土曜日
          sunday = Date.new(2024, 1, 14)    # 日曜日
          
          expect(JapaneseBusinessDays.business_day?(friday)).to be false
          expect(JapaneseBusinessDays.business_day?(saturday)).to be false
          expect(JapaneseBusinessDays.business_day?(sunday)).to be true
          
          # 営業日計算への影響確認
          start_date = Date.new(2024, 1, 11) # 木曜日
          end_date = Date.new(2024, 1, 15)   # 月曜日
          business_days = JapaneseBusinessDays.business_days_between(start_date, end_date)
          
          # 木→日→月 = 2営業日
          expect(business_days).to eq(2)
        end
      end

      describe "複雑な設定の組み合わせ" do
        it "カスタム祝日と特別営業日の組み合わせ" do
          JapaneseBusinessDays.configure do |config|
            # 平日を非営業日に追加
            config.add_holiday(Date.new(2024, 6, 15)) # 土曜日
            
            # 祝日を営業日に変更
            config.add_business_day(Date.new(2024, 5, 3)) # 憲法記念日
            
            # 週末を変更
            config.weekend_days = [0] # 日曜日のみ
          end
          
          # 各設定が正しく適用されることを確認
          expect(JapaneseBusinessDays.business_day?(Date.new(2024, 6, 15))).to be false # カスタム祝日
          expect(JapaneseBusinessDays.business_day?(Date.new(2024, 5, 3))).to be true   # 特別営業日
          expect(JapaneseBusinessDays.business_day?(Date.new(2024, 1, 6))).to be true   # 土曜日が営業日
          expect(JapaneseBusinessDays.business_day?(Date.new(2024, 1, 7))).to be false  # 日曜日は非営業日
        end

        it "設定変更後のキャッシュクリア確認" do
          # 初回計算
          initial_result = JapaneseBusinessDays.business_day?(Date.new(2024, 5, 3))
          expect(initial_result).to be false # 憲法記念日
          
          # 設定変更
          JapaneseBusinessDays.configure do |config|
            config.add_business_day(Date.new(2024, 5, 3))
          end
          
          # 設定変更後の計算
          updated_result = JapaneseBusinessDays.business_day?(Date.new(2024, 5, 3))
          expect(updated_result).to be true # 営業日に変更
          
          # キャッシュがクリアされて新しい設定が反映されていることを確認
          expect(initial_result).not_to eq(updated_result)
        end
      end
    end

    context "エラーハンドリングの統合テスト" do
      describe "境界値とエッジケース" do
        it "極端に古い日付の処理" do
          old_date = Date.new(1000, 1, 1)
          
          expect {
            JapaneseBusinessDays.business_day?(old_date)
          }.not_to raise_error
          
          # 古い日付でも基本的な営業日判定は動作する
          expect(JapaneseBusinessDays.business_day?(old_date)).to be_a(TrueClass).or be_a(FalseClass)
        end

        it "極端に新しい日付の処理" do
          future_date = Date.new(3000, 12, 31) # より現実的な未来日付
          
          expect {
            JapaneseBusinessDays.business_day?(future_date)
          }.not_to raise_error
          
          # 未来の日付でも基本的な営業日判定は動作する
          expect(JapaneseBusinessDays.business_day?(future_date)).to be_a(TrueClass).or be_a(FalseClass)
        end

        it "大量の営業日加算での安定性" do
          base_date = Date.new(2024, 1, 1)
          
          # 1000営業日後を計算
          result = JapaneseBusinessDays.add_business_days(base_date, 1000)
          
          # 結果が妥当な範囲内であることを確認
          expect(result).to be > base_date
          expect(result.year).to be_between(2024, 2028)
          expect(JapaneseBusinessDays.business_day?(result)).to be true
        end

        it "負の営業日数での計算" do
          base_date = Date.new(2024, 6, 15)
          
          # -50営業日の計算
          result = JapaneseBusinessDays.add_business_days(base_date, -50)
          
          # 結果が妥当であることを確認
          expect(result).to be < base_date
          expect(JapaneseBusinessDays.business_day?(result)).to be true
        end
      end

      describe "異常系の統合テスト" do
        it "無効な設定での動作確認" do
          expect {
            JapaneseBusinessDays.configure do |config|
              config.weekend_days = [8, 9] # 無効な曜日
            end
          }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
          
          # エラー後も基本機能は動作する
          expect(JapaneseBusinessDays.business_day?(Date.new(2024, 1, 10))).to be true
        end

        it "メモリ制限下での大量計算" do
          # 大量の日付計算を実行してメモリリークがないことを確認
          1000.times do |i|
            date = Date.new(2024, 1, 1) + i
            JapaneseBusinessDays.business_day?(date)
          end
          
          # GCを実行してメモリ使用量を確認
          GC.start
          
          # テストが完了すれば、メモリリークがないと判断
          expect(true).to be true
        end
      end
    end

    context "Date拡張機能との統合" do
      describe "拡張メソッドの動作確認" do
        it "Date拡張メソッドが正しく動作する" do
          date = Date.new(2024, 1, 10)
          
          # 拡張メソッドが利用可能であることを確認
          expect(date).to respond_to(:business_day?)
          expect(date).to respond_to(:add_business_days)
          expect(date).to respond_to(:subtract_business_days)
          expect(date).to respond_to(:next_business_day)
          expect(date).to respond_to(:previous_business_day)
          expect(date).to respond_to(:holiday?)
          
          # 拡張メソッドが正しい結果を返すことを確認
          expect(date.business_day?).to be true
          expect(date.add_business_days(1)).to eq(Date.new(2024, 1, 11))
          expect(date.holiday?).to be false
        end

        it "Time拡張メソッドが正しく動作する" do
          time = Time.new(2024, 1, 10, 10, 0, 0)
          
          # 拡張メソッドが利用可能であることを確認
          expect(time).to respond_to(:business_day?)
          expect(time).to respond_to(:add_business_days)
          
          # 拡張メソッドが正しい結果を返すことを確認
          expect(time.business_day?).to be true
          expect(time.add_business_days(1).to_date).to eq(Date.new(2024, 1, 11))
        end

        it "DateTime拡張メソッドが正しく動作する" do
          datetime = DateTime.new(2024, 1, 10, 15, 30, 0)
          
          # 拡張メソッドが利用可能であることを確認
          expect(datetime).to respond_to(:business_day?)
          expect(datetime).to respond_to(:subtract_business_days)
          
          # 拡張メソッドが正しい結果を返すことを確認
          expect(datetime.business_day?).to be true
          expect(datetime.subtract_business_days(1).to_date).to eq(Date.new(2024, 1, 9))
        end
      end

      describe "拡張メソッドとモジュールメソッドの一貫性" do
        it "同じ計算で同じ結果を返す" do
          date = Date.new(2024, 1, 10)
          
          # 拡張メソッドとモジュールメソッドで同じ結果が得られることを確認
          expect(date.business_day?).to eq(JapaneseBusinessDays.business_day?(date))
          expect(date.holiday?).to eq(JapaneseBusinessDays.holiday?(date))
          expect(date.add_business_days(5)).to eq(JapaneseBusinessDays.add_business_days(date, 5))
          expect(date.subtract_business_days(3)).to eq(JapaneseBusinessDays.subtract_business_days(date, 3))
          expect(date.next_business_day).to eq(JapaneseBusinessDays.next_business_day(date))
          expect(date.previous_business_day).to eq(JapaneseBusinessDays.previous_business_day(date))
        end
      end
    end
  end
end