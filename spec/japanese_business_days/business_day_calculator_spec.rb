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
end