# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JapaneseBusinessDays::BusinessDayCalculator do
  let(:holiday_calculator) { JapaneseBusinessDays::HolidayCalculator.new }
  let(:configuration) { JapaneseBusinessDays::Configuration.new }
  let(:calculator) { described_class.new(holiday_calculator, configuration) }

  describe '#business_day?' do
    context '平日の場合' do
      it '月曜日は営業日と判定される' do
        monday = Date.new(2024, 1, 15) # 2024年1月15日（月曜日）
        expect(calculator.business_day?(monday)).to be true
      end

      it '火曜日は営業日と判定される' do
        tuesday = Date.new(2024, 1, 9) # 2024年1月9日（火曜日）
        expect(calculator.business_day?(tuesday)).to be true
      end

      it '水曜日は営業日と判定される' do
        wednesday = Date.new(2024, 1, 10) # 2024年1月10日（水曜日）
        expect(calculator.business_day?(wednesday)).to be true
      end

      it '木曜日は営業日と判定される' do
        thursday = Date.new(2024, 1, 11) # 2024年1月11日（木曜日）
        expect(calculator.business_day?(thursday)).to be true
      end

      it '金曜日は営業日と判定される' do
        friday = Date.new(2024, 1, 12) # 2024年1月12日（金曜日）
        expect(calculator.business_day?(friday)).to be true
      end
    end

    context '週末の場合' do
      it '土曜日は営業日ではないと判定される' do
        saturday = Date.new(2024, 1, 6) # 2024年1月6日（土曜日）
        expect(calculator.business_day?(saturday)).to be false
      end

      it '日曜日は営業日ではないと判定される' do
        sunday = Date.new(2024, 1, 7) # 2024年1月7日（日曜日）
        expect(calculator.business_day?(sunday)).to be false
      end
    end

    context '祝日の場合' do
      it '元日は営業日ではないと判定される' do
        new_years_day = Date.new(2024, 1, 1) # 2024年1月1日（元日）
        expect(calculator.business_day?(new_years_day)).to be false
      end

      it '建国記念の日は営業日ではないと判定される' do
        national_foundation_day = Date.new(2024, 2, 11) # 2024年2月11日（建国記念の日）
        expect(calculator.business_day?(national_foundation_day)).to be false
      end

      it '成人の日（ハッピーマンデー）は営業日ではないと判定される' do
        coming_of_age_day = Date.new(2024, 1, 8) # 2024年1月8日（成人の日・第2月曜日）
        expect(calculator.business_day?(coming_of_age_day)).to be false
      end
    end

    context 'カスタム設定の場合' do
      it 'カスタム営業日として設定された祝日は営業日と判定される' do
        new_years_day = Date.new(2024, 1, 1) # 元日
        configuration.add_business_day(new_years_day)
        
        expect(calculator.business_day?(new_years_day)).to be true
      end

      it 'カスタム非営業日として設定された平日は営業日ではないと判定される' do
        regular_weekday = Date.new(2024, 1, 10) # 2024年1月10日（水曜日）
        configuration.add_holiday(regular_weekday)
        
        expect(calculator.business_day?(regular_weekday)).to be false
      end

      it 'カスタム週末設定で金曜日が週末の場合、金曜日は営業日ではないと判定される' do
        friday = Date.new(2024, 1, 12) # 2024年1月12日（金曜日）
        configuration.weekend_days = [5, 6] # 金曜日と土曜日を週末に設定
        
        expect(calculator.business_day?(friday)).to be false
      end
    end

    context '無効な引数の場合' do
      it 'Date以外のオブジェクトを渡すとInvalidArgumentErrorが発生する' do
        expect { calculator.business_day?("2024-01-01") }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      end

      it 'nilを渡すとInvalidArgumentErrorが発生する' do
        expect { calculator.business_day?(nil) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      end
    end
  end

  describe '#weekend?' do
    context 'デフォルト設定（土日が週末）の場合' do
      it '日曜日は週末と判定される' do
        sunday = Date.new(2024, 1, 7) # 2024年1月7日（日曜日）
        expect(calculator.send(:weekend?, sunday)).to be true
      end

      it '土曜日は週末と判定される' do
        saturday = Date.new(2024, 1, 6) # 2024年1月6日（土曜日）
        expect(calculator.send(:weekend?, saturday)).to be true
      end

      it '月曜日は週末ではないと判定される' do
        monday = Date.new(2024, 1, 8) # 2024年1月8日（月曜日）
        expect(calculator.send(:weekend?, monday)).to be false
      end
    end

    context 'カスタム週末設定の場合' do
      it '金曜日と土曜日を週末に設定した場合、金曜日は週末と判定される' do
        friday = Date.new(2024, 1, 12) # 2024年1月12日（金曜日）
        configuration.weekend_days = [5, 6] # 金曜日と土曜日
        
        expect(calculator.send(:weekend?, friday)).to be true
      end

      it '金曜日と土曜日を週末に設定した場合、日曜日は週末ではないと判定される' do
        sunday = Date.new(2024, 1, 7) # 2024年1月7日（日曜日）
        configuration.weekend_days = [5, 6] # 金曜日と土曜日
        
        expect(calculator.send(:weekend?, sunday)).to be false
      end
    end
  end

  describe '#non_business_day?' do
    it '週末は非営業日と判定される' do
      saturday = Date.new(2024, 1, 6) # 2024年1月6日（土曜日）
      expect(calculator.send(:non_business_day?, saturday)).to be true
    end

    it '祝日は非営業日と判定される' do
      new_years_day = Date.new(2024, 1, 1) # 2024年1月1日（元日）
      expect(calculator.send(:non_business_day?, new_years_day)).to be true
    end

    it 'カスタム非営業日は非営業日と判定される' do
      regular_day = Date.new(2024, 1, 10) # 2024年1月10日（水曜日）
      configuration.add_holiday(regular_day)
      
      expect(calculator.send(:non_business_day?, regular_day)).to be true
    end

    it 'カスタム営業日として設定された祝日は非営業日ではないと判定される' do
      new_years_day = Date.new(2024, 1, 1) # 元日
      configuration.add_business_day(new_years_day)
      
      expect(calculator.send(:non_business_day?, new_years_day)).to be false
    end

    it '平日は非営業日ではないと判定される' do
      monday = Date.new(2024, 1, 15) # 2024年1月15日（月曜日）
      expect(calculator.send(:non_business_day?, monday)).to be false
    end
  end

  describe '#business_days_between' do
    context '基本的な営業日数計算' do
      it '同じ日付の場合は0を返す' do
        date = Date.new(2024, 1, 15) # 2024年1月15日（月曜日）
        expect(calculator.business_days_between(date, date)).to eq(0)
      end

      it '連続する営業日の場合は正しい日数を返す' do
        monday = Date.new(2024, 1, 15) # 2024年1月15日（月曜日）
        friday = Date.new(2024, 1, 19) # 2024年1月19日（金曜日）
        expect(calculator.business_days_between(monday, friday)).to eq(4)
      end

      it '1日の差がある営業日の場合は1を返す' do
        monday = Date.new(2024, 1, 15) # 2024年1月15日（月曜日）
        tuesday = Date.new(2024, 1, 16) # 2024年1月16日（火曜日）
        expect(calculator.business_days_between(monday, tuesday)).to eq(1)
      end
    end

    context '週末を含む期間' do
      it '週末をまたぐ期間で正しい営業日数を返す' do
        friday = Date.new(2024, 1, 12) # 2024年1月12日（金曜日）
        monday = Date.new(2024, 1, 15) # 2024年1月15日（月曜日）
        expect(calculator.business_days_between(friday, monday)).to eq(1)
      end

      it '複数の週末を含む期間で正しい営業日数を返す' do
        monday1 = Date.new(2024, 1, 8) # 2024年1月8日（月曜日）
        friday2 = Date.new(2024, 1, 19) # 2024年1月19日（金曜日）
        # 1/8(月) -> 1/19(金): 1/9-1/12(4日) + 1/15-1/19(5日) = 9営業日
        expect(calculator.business_days_between(monday1, friday2)).to eq(9)
      end
    end

    context '祝日を含む期間' do
      it '祝日を含む期間で正しい営業日数を返す' do
        # 2024年1月1日（元日）を含む期間
        dec_29 = Date.new(2023, 12, 29) # 2023年12月29日（金曜日）
        jan_4 = Date.new(2024, 1, 4) # 2024年1月4日（木曜日）
        # 12/29(金) -> 1/4(木): 1/2(火), 1/3(水), 1/4(木) = 3営業日
        # （1/1は元日、12/30-31と1/6-7は週末）
        expect(calculator.business_days_between(dec_29, jan_4)).to eq(3)
      end

      it 'ハッピーマンデー祝日を含む期間で正しい営業日数を返す' do
        # 2024年1月8日（成人の日・第2月曜日）を含む期間
        jan_5 = Date.new(2024, 1, 5) # 2024年1月5日（金曜日）
        jan_10 = Date.new(2024, 1, 10) # 2024年1月10日（水曜日）
        # 1/5(金) -> 1/10(水): 1/9(火), 1/10(水) = 2営業日
        # （1/8は成人の日、1/6-7は週末）
        expect(calculator.business_days_between(jan_5, jan_10)).to eq(2)
      end
    end

    context '逆順の日付' do
      it '開始日が終了日より後の場合は負の値を返す' do
        friday = Date.new(2024, 1, 19) # 2024年1月19日（金曜日）
        monday = Date.new(2024, 1, 15) # 2024年1月15日（月曜日）
        expect(calculator.business_days_between(friday, monday)).to eq(-4)
      end

      it '祝日を含む逆順の期間で正しい負の値を返す' do
        jan_10 = Date.new(2024, 1, 10) # 2024年1月10日（水曜日）
        jan_5 = Date.new(2024, 1, 5) # 2024年1月5日（金曜日）
        expect(calculator.business_days_between(jan_10, jan_5)).to eq(-2)
      end
    end

    context '年をまたぐ期間' do
      it '年をまたぐ期間で正しい営業日数を返す' do
        dec_28 = Date.new(2023, 12, 28) # 2023年12月28日（木曜日）
        jan_5 = Date.new(2024, 1, 5) # 2024年1月5日（金曜日）
        # 12/28(木) -> 1/5(金): 12/29(金), 1/2(火), 1/3(水), 1/4(木), 1/5(金) = 5営業日
        # （1/1は元日、12/30-31と1/6-7は週末）
        expect(calculator.business_days_between(dec_28, jan_5)).to eq(5)
      end
    end

    context 'カスタム設定を含む期間' do
      it 'カスタム営業日を含む期間で正しい営業日数を返す' do
        # 元日をカスタム営業日として設定
        new_years_day = Date.new(2024, 1, 1)
        configuration.add_business_day(new_years_day)
        
        dec_29 = Date.new(2023, 12, 29) # 2023年12月29日（金曜日）
        jan_4 = Date.new(2024, 1, 4) # 2024年1月4日（木曜日）
        # 12/29(金) -> 1/4(木): 1/1(月・カスタム営業日), 1/2(火), 1/3(水), 1/4(木) = 4営業日
        expect(calculator.business_days_between(dec_29, jan_4)).to eq(4)
      end

      it 'カスタム非営業日を含む期間で正しい営業日数を返す' do
        # 平日をカスタム非営業日として設定
        jan_10 = Date.new(2024, 1, 10) # 2024年1月10日（水曜日）
        configuration.add_holiday(jan_10)
        
        jan_9 = Date.new(2024, 1, 9) # 2024年1月9日（火曜日）
        jan_11 = Date.new(2024, 1, 11) # 2024年1月11日（木曜日）
        # 1/9(火) -> 1/11(木): 1/11(木) = 1営業日
        # （1/10はカスタム非営業日）
        expect(calculator.business_days_between(jan_9, jan_11)).to eq(1)
      end
    end

    context '無効な引数' do
      it 'start_dateがDate以外の場合はInvalidArgumentErrorが発生する' do
        end_date = Date.new(2024, 1, 15)
        expect { calculator.business_days_between("2024-01-10", end_date) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      end

      it 'end_dateがDate以外の場合はInvalidArgumentErrorが発生する' do
        start_date = Date.new(2024, 1, 10)
        expect { calculator.business_days_between(start_date, "2024-01-15") }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      end

      it 'nilが渡された場合はInvalidArgumentErrorが発生する' do
        date = Date.new(2024, 1, 15)
        expect { calculator.business_days_between(nil, date) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
        expect { calculator.business_days_between(date, nil) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      end
    end
  end
end