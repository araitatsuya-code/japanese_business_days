# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JapaneseBusinessDays::DateExtensions do
  # テスト用のクラスを作成してモジュールをinclude
  let(:test_date_class) do
    Class.new(Date) do
      include JapaneseBusinessDays::DateExtensions
    end
  end

  let(:test_time_class) do
    Class.new(Time) do
      include JapaneseBusinessDays::DateExtensions
    end
  end

  let(:test_datetime_class) do
    Class.new(DateTime) do
      include JapaneseBusinessDays::DateExtensions
    end
  end

  before do
    # 設定をリセット
    JapaneseBusinessDays.instance_variable_set(:@configuration, nil)
    JapaneseBusinessDays.instance_variable_set(:@holiday_calculator, nil)
    JapaneseBusinessDays.instance_variable_set(:@business_day_calculator, nil)
  end

  describe 'Date拡張' do
    let(:date) { test_date_class.new(2024, 1, 15) } # 月曜日（営業日）
    let(:holiday_date) { test_date_class.new(2024, 1, 1) } # 元日（祝日）
    let(:weekend_date) { test_date_class.new(2024, 1, 13) } # 土曜日

    describe '#add_business_days' do
      it '営業日を正しく加算する' do
        result = date.add_business_days(5)
        expect(result).to eq(Date.new(2024, 1, 22)) # 5営業日後
      end

      it '0日加算の場合、営業日であればその日を返す' do
        result = date.add_business_days(0)
        expect(result).to eq(date)
      end

      it '0日加算の場合、非営業日であれば次の営業日を返す' do
        result = weekend_date.add_business_days(0)
        expect(result).to eq(Date.new(2024, 1, 15)) # 次の月曜日
      end

      it '負の日数を指定した場合、減算として処理する' do
        result = date.add_business_days(-3)
        expected = date.subtract_business_days(3)
        expect(result).to eq(expected)
      end

      it '無効な引数でエラーを発生させる' do
        expect { date.add_business_days("invalid") }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      end
    end

    describe '#subtract_business_days' do
      it '営業日を正しく減算する' do
        result = date.subtract_business_days(5)
        expect(result).to eq(Date.new(2024, 1, 5)) # 5営業日前（1/8は成人の日のため1/5）
      end

      it '0日減算の場合、営業日であればその日を返す' do
        result = date.subtract_business_days(0)
        expect(result).to eq(date)
      end

      it '0日減算の場合、非営業日であれば次の営業日を返す' do
        result = weekend_date.subtract_business_days(0)
        expect(result).to eq(Date.new(2024, 1, 15)) # 次の月曜日
      end

      it '負の日数を指定した場合、加算として処理する' do
        result = date.subtract_business_days(-3)
        expected = date.add_business_days(3)
        expect(result).to eq(expected)
      end

      it '無効な引数でエラーを発生させる' do
        expect { date.subtract_business_days("invalid") }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      end
    end

    describe '#business_day?' do
      it '営業日の場合trueを返す' do
        expect(date.business_day?).to be true
      end

      it '土曜日の場合falseを返す' do
        expect(weekend_date.business_day?).to be false
      end

      it '日曜日の場合falseを返す' do
        sunday = test_date_class.new(2024, 1, 14)
        expect(sunday.business_day?).to be false
      end

      it '祝日の場合falseを返す' do
        expect(holiday_date.business_day?).to be false
      end
    end

    describe '#holiday?' do
      it '祝日の場合trueを返す' do
        expect(holiday_date.holiday?).to be true
      end

      it '平日の場合falseを返す' do
        expect(date.holiday?).to be false
      end

      it '土日の場合falseを返す（祝日ではないため）' do
        expect(weekend_date.holiday?).to be false
      end
    end

    describe '#next_business_day' do
      it '営業日の次の営業日を返す' do
        result = date.next_business_day
        expect(result).to eq(Date.new(2024, 1, 16)) # 火曜日
      end

      it '金曜日の次の営業日は月曜日を返す' do
        friday = test_date_class.new(2024, 1, 12)
        result = friday.next_business_day
        expect(result).to eq(Date.new(2024, 1, 15)) # 月曜日
      end

      it '祝日の次の営業日を正しく返す' do
        result = holiday_date.next_business_day
        expect(result).to eq(Date.new(2024, 1, 2)) # 1月2日（火曜日）
      end
    end

    describe '#previous_business_day' do
      it '営業日の前の営業日を返す' do
        result = date.previous_business_day
        expect(result).to eq(Date.new(2024, 1, 12)) # 金曜日
      end

      it '月曜日の前の営業日は金曜日を返す' do
        monday = test_date_class.new(2024, 1, 15)
        result = monday.previous_business_day
        expect(result).to eq(Date.new(2024, 1, 12)) # 金曜日
      end

      it '祝日の前の営業日を正しく返す' do
        # 1月2日（火曜日）の前の営業日
        jan_2 = test_date_class.new(2024, 1, 2)
        result = jan_2.previous_business_day
        expect(result).to eq(Date.new(2023, 12, 29)) # 2023年12月29日（金曜日）
      end
    end
  end

  describe 'Time拡張' do
    let(:time) { test_time_class.new(2024, 1, 15, 10, 30, 0) } # 月曜日 10:30（営業日）
    let(:holiday_time) { test_time_class.new(2024, 1, 1, 12, 0, 0) } # 元日 12:00（祝日）

    describe '#add_business_days' do
      it 'Timeオブジェクトで営業日を正しく加算する' do
        result = time.add_business_days(3)
        expected = test_time_class.new(2024, 1, 18, 10, 30, 0) # 3営業日後の木曜日、時刻は保持
        expect(result).to eq(expected)
      end

      it 'Timeオブジェクトで営業日を減算し時刻を保持する' do
        result = time.subtract_business_days(2)
        expected = test_time_class.new(2024, 1, 11, 10, 30, 0) # 2営業日前の木曜日、時刻は保持
        expect(result).to eq(expected)
      end
    end

    describe '#business_day?' do
      it 'Timeオブジェクトで営業日判定を正しく行う' do
        expect(time.business_day?).to be true
        expect(holiday_time.business_day?).to be false
      end
    end

    describe '#holiday?' do
      it 'Timeオブジェクトで祝日判定を正しく行う' do
        expect(time.holiday?).to be false
        expect(holiday_time.holiday?).to be true
      end
    end

    describe '#next_business_day' do
      it 'Timeオブジェクトで次の営業日を正しく返す' do
        result = time.next_business_day
        expected = test_time_class.new(2024, 1, 16, 10, 30, 0) # 火曜日、時刻は保持
        expect(result).to eq(expected)
      end
    end

    describe '#previous_business_day' do
      it 'Timeオブジェクトで前の営業日を正しく返す' do
        result = time.previous_business_day
        expected = test_time_class.new(2024, 1, 12, 10, 30, 0) # 金曜日、時刻は保持
        expect(result).to eq(expected)
      end
    end
  end

  describe 'DateTime拡張' do
    let(:datetime) { test_datetime_class.new(2024, 1, 15, 14, 45, 30) } # 月曜日 14:45:30（営業日）
    let(:holiday_datetime) { test_datetime_class.new(2024, 1, 1, 9, 15, 0) } # 元日 9:15（祝日）

    describe '#add_business_days' do
      it 'DateTimeオブジェクトで営業日を正しく加算する' do
        result = datetime.add_business_days(2)
        expected = test_datetime_class.new(2024, 1, 17, 14, 45, 30) # 2営業日後の水曜日、時刻は保持
        expect(result).to eq(expected)
      end
    end

    describe '#business_day?' do
      it 'DateTimeオブジェクトで営業日判定を正しく行う' do
        expect(datetime.business_day?).to be true
        expect(holiday_datetime.business_day?).to be false
      end
    end

    describe '#holiday?' do
      it 'DateTimeオブジェクトで祝日判定を正しく行う' do
        expect(datetime.holiday?).to be false
        expect(holiday_datetime.holiday?).to be true
      end
    end

    describe '#next_business_day' do
      it 'DateTimeオブジェクトで次の営業日を正しく返す' do
        result = datetime.next_business_day
        expected = test_datetime_class.new(2024, 1, 16, 14, 45, 30) # 火曜日、時刻は保持
        expect(result).to eq(expected)
      end
    end

    describe '#previous_business_day' do
      it 'DateTimeオブジェクトで前の営業日を正しく返す' do
        result = datetime.previous_business_day
        expected = test_datetime_class.new(2024, 1, 12, 14, 45, 30) # 金曜日、時刻は保持
        expect(result).to eq(expected)
      end
    end
  end

  describe 'エラーハンドリング' do
    let(:unsupported_object) do
      Class.new do
        include JapaneseBusinessDays::DateExtensions
      end.new
    end

    it 'サポートされていないオブジェクトでエラーを発生させる' do
      expect { unsupported_object.business_day? }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Unsupported date type/)
    end
  end

  describe 'カスタム設定との統合' do
    before do
      JapaneseBusinessDays.configure do |config|
        config.add_holiday(Date.new(2024, 1, 15)) # 月曜日をカスタム祝日に設定
        config.add_business_day(Date.new(2024, 1, 13)) # 土曜日をカスタム営業日に設定
      end
    end

    let(:custom_holiday_date) { test_date_class.new(2024, 1, 15) } # カスタム祝日
    let(:custom_business_date) { test_date_class.new(2024, 1, 13) } # カスタム営業日

    it 'カスタム祝日を正しく処理する' do
      expect(custom_holiday_date.business_day?).to be false
      expect(custom_holiday_date.holiday?).to be false # カスタム祝日は祝日判定ではfalse
    end

    it 'カスタム営業日を正しく処理する' do
      expect(custom_business_date.business_day?).to be true
    end
  end

  describe '年をまたぐ計算' do
    let(:year_end_date) { test_date_class.new(2023, 12, 29) } # 2023年12月29日（金曜日）

    it '年をまたいで営業日を正しく加算する' do
      result = year_end_date.add_business_days(3)
      expect(result).to eq(Date.new(2024, 1, 4)) # 2024年1月4日（木曜日）
    end

    it '年をまたいで営業日を正しく減算する' do
      jan_4 = test_date_class.new(2024, 1, 4)
      result = jan_4.subtract_business_days(3)
      expect(result).to eq(Date.new(2023, 12, 29)) # 2023年12月29日（金曜日）
    end
  end

  describe 'パフォーマンステスト' do
    let(:date) { test_date_class.new(2024, 1, 15) }

    it '大量の営業日計算が効率的に実行される' do
      start_time = Time.now
      
      100.times do |i|
        date.add_business_days(i % 10)
        date.business_day?
        date.next_business_day
      end
      
      end_time = Time.now
      execution_time = end_time - start_time
      
      # 100回の計算が1秒以内に完了することを確認
      expect(execution_time).to be < 1.0
    end
  end
end