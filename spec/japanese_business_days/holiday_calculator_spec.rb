# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JapaneseBusinessDays::HolidayCalculator do
  let(:calculator) { described_class.new }

  describe '#initialize' do
    it 'creates a new instance' do
      expect(calculator).to be_a(described_class)
    end
  end

  describe '#holiday?' do
    context 'with valid date input' do
      it 'accepts Date objects' do
        expect { calculator.holiday?(Date.new(2024, 1, 1)) }.not_to raise_error
      end

      it 'accepts Time objects' do
        expect { calculator.holiday?(Time.new(2024, 1, 1)) }.not_to raise_error
      end

      it 'accepts DateTime objects' do
        expect { calculator.holiday?(DateTime.new(2024, 1, 1)) }.not_to raise_error
      end

      it 'accepts String objects' do
        expect { calculator.holiday?('2024-01-01') }.not_to raise_error
      end
    end

    context 'with invalid date input' do
      it 'raises InvalidArgumentError for nil' do
        expect { calculator.holiday?(nil) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      end

      it 'raises InvalidArgumentError for invalid class' do
        expect { calculator.holiday?(123) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      end

      it 'raises InvalidArgumentError for invalid date string' do
        expect { calculator.holiday?('invalid-date') }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      end
    end

    context 'basic functionality' do
      it 'returns false for regular weekdays' do
        # 2024年1月2日は火曜日（平日）
        expect(calculator.holiday?(Date.new(2024, 1, 2))).to be false
      end

      it 'returns false for weekends (non-holidays)' do
        # 2024年1月6日は土曜日
        expect(calculator.holiday?(Date.new(2024, 1, 6))).to be false
      end
    end
  end

  describe '#holidays_in_year' do
    context 'with valid year input' do
      it 'accepts valid year integers' do
        expect { calculator.holidays_in_year(2024) }.not_to raise_error
      end

      it 'returns an array' do
        result = calculator.holidays_in_year(2024)
        expect(result).to be_an(Array)
      end

      it 'returns Holiday objects' do
        result = calculator.holidays_in_year(2024)
        result.each do |holiday|
          expect(holiday).to be_a(JapaneseBusinessDays::Holiday)
        end
      end
    end

    context 'with invalid year input' do
      it 'raises InvalidArgumentError for non-integer' do
        expect { calculator.holidays_in_year('2024') }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      end

      it 'raises InvalidArgumentError for year too small' do
        expect { calculator.holidays_in_year(999) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      end

      it 'raises InvalidArgumentError for year too large' do
        expect { calculator.holidays_in_year(10000) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      end
    end
  end

  describe '#substitute_holiday?' do
    context 'with valid date input' do
      it 'accepts Date objects' do
        expect { calculator.substitute_holiday?(Date.new(2024, 1, 1)) }.not_to raise_error
      end

      it 'returns false for non-Monday dates' do
        # 2024年1月1日は月曜日ではない
        expect(calculator.substitute_holiday?(Date.new(2024, 1, 1))).to be false
      end

      it 'returns false for Monday when previous day is not Sunday' do
        # 2024年1月8日は月曜日だが、前日は日曜日ではない
        expect(calculator.substitute_holiday?(Date.new(2024, 1, 8))).to be false
      end
    end

    context 'with invalid date input' do
      it 'raises InvalidArgumentError for invalid input' do
        expect { calculator.substitute_holiday?(nil) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      end
    end
  end

  describe 'fixed holidays' do
    describe '#holiday?' do
      it 'returns true for 元日 (New Year\'s Day)' do
        expect(calculator.holiday?(Date.new(2024, 1, 1))).to be true
      end

      it 'returns true for 建国記念の日 (National Foundation Day)' do
        expect(calculator.holiday?(Date.new(2024, 2, 11))).to be true
      end

      it 'returns true for 昭和の日 (Showa Day)' do
        expect(calculator.holiday?(Date.new(2024, 4, 29))).to be true
      end

      it 'returns true for 憲法記念日 (Constitution Memorial Day)' do
        expect(calculator.holiday?(Date.new(2024, 5, 3))).to be true
      end

      it 'returns true for みどりの日 (Greenery Day)' do
        expect(calculator.holiday?(Date.new(2024, 5, 4))).to be true
      end

      it 'returns true for こどもの日 (Children\'s Day)' do
        expect(calculator.holiday?(Date.new(2024, 5, 5))).to be true
      end

      it 'returns true for 山の日 (Mountain Day)' do
        expect(calculator.holiday?(Date.new(2024, 8, 11))).to be true
      end

      it 'returns true for 文化の日 (Culture Day)' do
        expect(calculator.holiday?(Date.new(2024, 11, 3))).to be true
      end

      it 'returns true for 勤労感謝の日 (Labor Thanksgiving Day)' do
        expect(calculator.holiday?(Date.new(2024, 11, 23))).to be true
      end

      it 'returns true for 天皇誕生日 (Emperor\'s Birthday)' do
        expect(calculator.holiday?(Date.new(2024, 12, 23))).to be true
      end

      it 'works across different years' do
        expect(calculator.holiday?(Date.new(2023, 1, 1))).to be true
        expect(calculator.holiday?(Date.new(2025, 1, 1))).to be true
      end

      it 'returns false for non-holidays' do
        expect(calculator.holiday?(Date.new(2024, 1, 2))).to be false
        expect(calculator.holiday?(Date.new(2024, 6, 15))).to be false
      end
    end

    describe '#holidays_in_year' do
      let(:holidays_2024) { calculator.holidays_in_year(2024) }

      it 'returns all fixed holidays for the year' do
        fixed_holidays = holidays_2024.select { |h| h.type == :fixed }
        expect(fixed_holidays.length).to eq(10)
      end

      it 'includes 元日' do
        new_year = holidays_2024.find { |h| h.name == "元日" }
        expect(new_year).not_to be_nil
        expect(new_year.date).to eq(Date.new(2024, 1, 1))
        expect(new_year.type).to eq(:fixed)
      end

      it 'includes 建国記念の日' do
        foundation_day = holidays_2024.find { |h| h.name == "建国記念の日" }
        expect(foundation_day).not_to be_nil
        expect(foundation_day.date).to eq(Date.new(2024, 2, 11))
        expect(foundation_day.type).to eq(:fixed)
      end

      it 'includes 昭和の日' do
        showa_day = holidays_2024.find { |h| h.name == "昭和の日" }
        expect(showa_day).not_to be_nil
        expect(showa_day.date).to eq(Date.new(2024, 4, 29))
        expect(showa_day.type).to eq(:fixed)
      end

      it 'includes Golden Week holidays' do
        constitution_day = holidays_2024.find { |h| h.name == "憲法記念日" }
        greenery_day = holidays_2024.find { |h| h.name == "みどりの日" }
        children_day = holidays_2024.find { |h| h.name == "こどもの日" }

        expect(constitution_day.date).to eq(Date.new(2024, 5, 3))
        expect(greenery_day.date).to eq(Date.new(2024, 5, 4))
        expect(children_day.date).to eq(Date.new(2024, 5, 5))
      end

      it 'includes 山の日' do
        mountain_day = holidays_2024.find { |h| h.name == "山の日" }
        expect(mountain_day).not_to be_nil
        expect(mountain_day.date).to eq(Date.new(2024, 8, 11))
        expect(mountain_day.type).to eq(:fixed)
      end

      it 'includes autumn holidays' do
        culture_day = holidays_2024.find { |h| h.name == "文化の日" }
        labor_day = holidays_2024.find { |h| h.name == "勤労感謝の日" }

        expect(culture_day.date).to eq(Date.new(2024, 11, 3))
        expect(labor_day.date).to eq(Date.new(2024, 11, 23))
      end

      it 'includes 天皇誕生日' do
        emperor_birthday = holidays_2024.find { |h| h.name == "天皇誕生日" }
        expect(emperor_birthday).not_to be_nil
        expect(emperor_birthday.date).to eq(Date.new(2024, 12, 23))
        expect(emperor_birthday.type).to eq(:fixed)
      end

      it 'returns holidays sorted by date' do
        dates = holidays_2024.map(&:date)
        expect(dates).to eq(dates.sort)
      end
    end
  end

  describe 'calculated holidays (equinoxes)' do
    describe '#holiday?' do
      # 実際の春分の日・秋分の日のテストデータ（国立天文台による）
      it 'returns true for 春分の日 (Vernal Equinox Day) in various years' do
        # 2024年の春分の日は3月20日
        expect(calculator.holiday?(Date.new(2024, 3, 20))).to be true
        # 2023年の春分の日は3月21日
        expect(calculator.holiday?(Date.new(2023, 3, 21))).to be true
        # 2025年の春分の日は3月20日
        expect(calculator.holiday?(Date.new(2025, 3, 20))).to be true
      end

      it 'returns true for 秋分の日 (Autumnal Equinox Day) in various years' do
        # 2024年の秋分の日は9月22日
        expect(calculator.holiday?(Date.new(2024, 9, 22))).to be true
        # 2023年の秋分の日は9月23日
        expect(calculator.holiday?(Date.new(2023, 9, 23))).to be true
        # 2025年の秋分の日は9月23日
        expect(calculator.holiday?(Date.new(2025, 9, 23))).to be true
      end

      it 'returns false for dates near but not on equinox days' do
        # 春分の日の前後
        expect(calculator.holiday?(Date.new(2024, 3, 19))).to be false
        expect(calculator.holiday?(Date.new(2024, 3, 21))).to be false
        
        # 秋分の日の前後（2024年9月22日は日曜日なので9月23日は振替休日になる）
        expect(calculator.holiday?(Date.new(2024, 9, 21))).to be false
        expect(calculator.holiday?(Date.new(2024, 9, 24))).to be false
      end
    end

    describe '#holidays_in_year' do
      let(:holidays_2024) { calculator.holidays_in_year(2024) }

      it 'includes calculated holidays' do
        calculated_holidays = holidays_2024.select { |h| h.type == :calculated }
        expect(calculated_holidays.length).to eq(2)
      end

      it 'includes 春分の日' do
        vernal_equinox = holidays_2024.find { |h| h.name == "春分の日" }
        expect(vernal_equinox).not_to be_nil
        expect(vernal_equinox.date).to eq(Date.new(2024, 3, 20))
        expect(vernal_equinox.type).to eq(:calculated)
      end

      it 'includes 秋分の日' do
        autumnal_equinox = holidays_2024.find { |h| h.name == "秋分の日" }
        expect(autumnal_equinox).not_to be_nil
        expect(autumnal_equinox.date).to eq(Date.new(2024, 9, 22))
        expect(autumnal_equinox.type).to eq(:calculated)
      end

      it 'calculates correct dates for different years' do
        holidays_2023 = calculator.holidays_in_year(2023)
        holidays_2025 = calculator.holidays_in_year(2025)

        vernal_2023 = holidays_2023.find { |h| h.name == "春分の日" }
        vernal_2025 = holidays_2025.find { |h| h.name == "春分の日" }
        
        expect(vernal_2023.date).to eq(Date.new(2023, 3, 21))
        expect(vernal_2025.date).to eq(Date.new(2025, 3, 20))

        autumnal_2023 = holidays_2023.find { |h| h.name == "秋分の日" }
        autumnal_2025 = holidays_2025.find { |h| h.name == "秋分の日" }
        
        expect(autumnal_2023.date).to eq(Date.new(2023, 9, 23))
        expect(autumnal_2025.date).to eq(Date.new(2025, 9, 23))
      end
    end

    describe 'astronomical calculations' do
      it 'calculates vernal equinox correctly for known years' do
        # テスト用の内部メソッドアクセス（通常は推奨されないが、計算の正確性確認のため）
        expect(calculator.send(:vernal_equinox_day, 2024)).to eq(Date.new(2024, 3, 20))
        expect(calculator.send(:vernal_equinox_day, 2023)).to eq(Date.new(2023, 3, 21))
        expect(calculator.send(:vernal_equinox_day, 2025)).to eq(Date.new(2025, 3, 20))
      end

      it 'calculates autumnal equinox correctly for known years' do
        expect(calculator.send(:autumnal_equinox_day, 2024)).to eq(Date.new(2024, 9, 22))
        expect(calculator.send(:autumnal_equinox_day, 2023)).to eq(Date.new(2023, 9, 23))
        expect(calculator.send(:autumnal_equinox_day, 2025)).to eq(Date.new(2025, 9, 23))
      end

      it 'handles edge case years' do
        # 計算式の境界年をテスト
        expect { calculator.send(:vernal_equinox_day, 1900) }.not_to raise_error
        expect { calculator.send(:vernal_equinox_day, 2099) }.not_to raise_error
        expect { calculator.send(:autumnal_equinox_day, 1900) }.not_to raise_error
        expect { calculator.send(:autumnal_equinox_day, 2099) }.not_to raise_error
      end
    end
  end

  describe 'Happy Monday holidays' do
    describe '#holiday?' do
      it 'returns true for 成人の日 (Coming of Age Day) - 2nd Monday of January' do
        # 2024年1月8日は第2月曜日
        expect(calculator.holiday?(Date.new(2024, 1, 8))).to be true
        # 2023年1月9日は第2月曜日
        expect(calculator.holiday?(Date.new(2023, 1, 9))).to be true
        # 2025年1月13日は第2月曜日
        expect(calculator.holiday?(Date.new(2025, 1, 13))).to be true
      end

      it 'returns true for 海の日 (Marine Day) - 3rd Monday of July' do
        # 2024年7月15日は第3月曜日
        expect(calculator.holiday?(Date.new(2024, 7, 15))).to be true
        # 2023年7月17日は第3月曜日
        expect(calculator.holiday?(Date.new(2023, 7, 17))).to be true
        # 2025年7月21日は第3月曜日
        expect(calculator.holiday?(Date.new(2025, 7, 21))).to be true
      end

      it 'returns true for 敬老の日 (Respect for the Aged Day) - 3rd Monday of September' do
        # 2024年9月16日は第3月曜日
        expect(calculator.holiday?(Date.new(2024, 9, 16))).to be true
        # 2023年9月18日は第3月曜日
        expect(calculator.holiday?(Date.new(2023, 9, 18))).to be true
        # 2025年9月15日は第3月曜日
        expect(calculator.holiday?(Date.new(2025, 9, 15))).to be true
      end

      it 'returns true for スポーツの日 (Sports Day) - 2nd Monday of October' do
        # 2024年10月14日は第2月曜日
        expect(calculator.holiday?(Date.new(2024, 10, 14))).to be true
        # 2023年10月9日は第2月曜日
        expect(calculator.holiday?(Date.new(2023, 10, 9))).to be true
        # 2025年10月13日は第2月曜日
        expect(calculator.holiday?(Date.new(2025, 10, 13))).to be true
      end

      it 'returns false for non-Monday dates in Happy Monday months' do
        # 1月の火曜日
        expect(calculator.holiday?(Date.new(2024, 1, 9))).to be false
        # 7月の日曜日
        expect(calculator.holiday?(Date.new(2024, 7, 14))).to be false
        # 9月の金曜日
        expect(calculator.holiday?(Date.new(2024, 9, 13))).to be false
        # 10月の土曜日
        expect(calculator.holiday?(Date.new(2024, 10, 12))).to be false
      end

      it 'returns false for wrong Monday weeks' do
        # 1月の第3月曜日（成人の日は第2月曜日）- 2024年1月15日
        expect(calculator.holiday?(Date.new(2024, 1, 15))).to be false
        # 7月の第2月曜日（海の日は第3月曜日）- 2024年7月8日
        expect(calculator.holiday?(Date.new(2024, 7, 8))).to be false
      end
    end

    describe '#holidays_in_year' do
      let(:holidays_2024) { calculator.holidays_in_year(2024) }

      it 'includes Happy Monday holidays' do
        happy_monday_holidays = holidays_2024.select { |h| h.type == :happy_monday }
        expect(happy_monday_holidays.length).to eq(4)
      end

      it 'includes 成人の日' do
        coming_of_age_day = holidays_2024.find { |h| h.name == "成人の日" }
        expect(coming_of_age_day).not_to be_nil
        expect(coming_of_age_day.date).to eq(Date.new(2024, 1, 8))
        expect(coming_of_age_day.type).to eq(:happy_monday)
      end

      it 'includes 海の日' do
        marine_day = holidays_2024.find { |h| h.name == "海の日" }
        expect(marine_day).not_to be_nil
        expect(marine_day.date).to eq(Date.new(2024, 7, 15))
        expect(marine_day.type).to eq(:happy_monday)
      end

      it 'includes 敬老の日' do
        respect_aged_day = holidays_2024.find { |h| h.name == "敬老の日" }
        expect(respect_aged_day).not_to be_nil
        expect(respect_aged_day.date).to eq(Date.new(2024, 9, 16))
        expect(respect_aged_day.type).to eq(:happy_monday)
      end

      it 'includes スポーツの日' do
        sports_day = holidays_2024.find { |h| h.name == "スポーツの日" }
        expect(sports_day).not_to be_nil
        expect(sports_day.date).to eq(Date.new(2024, 10, 14))
        expect(sports_day.type).to eq(:happy_monday)
      end

      it 'calculates correct dates for different years' do
        holidays_2023 = calculator.holidays_in_year(2023)
        holidays_2025 = calculator.holidays_in_year(2025)

        # 2023年の成人の日
        coming_of_age_2023 = holidays_2023.find { |h| h.name == "成人の日" }
        expect(coming_of_age_2023.date).to eq(Date.new(2023, 1, 9))

        # 2025年の成人の日
        coming_of_age_2025 = holidays_2025.find { |h| h.name == "成人の日" }
        expect(coming_of_age_2025.date).to eq(Date.new(2025, 1, 13))
      end
    end

    describe 'nth_weekday calculation' do
      it 'calculates nth weekday correctly' do
        # 2024年1月の第2月曜日
        expect(calculator.send(:nth_weekday, 2024, 1, 2, 1)).to eq(Date.new(2024, 1, 8))
        # 2024年7月の第3月曜日
        expect(calculator.send(:nth_weekday, 2024, 7, 3, 1)).to eq(Date.new(2024, 7, 15))
        # 2024年9月の第3月曜日
        expect(calculator.send(:nth_weekday, 2024, 9, 3, 1)).to eq(Date.new(2024, 9, 16))
        # 2024年10月の第2月曜日
        expect(calculator.send(:nth_weekday, 2024, 10, 2, 1)).to eq(Date.new(2024, 10, 14))
      end

      it 'handles different weekdays' do
        # 2024年1月の第1日曜日
        expect(calculator.send(:nth_weekday, 2024, 1, 1, 0)).to eq(Date.new(2024, 1, 7))
        # 2024年1月の第1火曜日
        expect(calculator.send(:nth_weekday, 2024, 1, 1, 2)).to eq(Date.new(2024, 1, 2))
      end

      it 'raises error for invalid nth weekday' do
        # 2024年2月には第5月曜日は存在しない
        expect { calculator.send(:nth_weekday, 2024, 2, 5, 1) }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'substitute holidays (振替休日)' do
    describe '#substitute_holiday?' do
      it 'returns true when Monday follows a Sunday holiday' do
        # 2024年9月22日（秋分の日）は日曜日、9月23日（月曜日）は振替休日
        expect(calculator.substitute_holiday?(Date.new(2024, 9, 23))).to be true
      end

      it 'returns false when Monday does not follow a Sunday holiday' do
        # 2024年1月8日は月曜日だが、前日（1月7日）は祝日ではない
        expect(calculator.substitute_holiday?(Date.new(2024, 1, 8))).to be false
      end

      it 'returns false for non-Monday dates' do
        # 火曜日
        expect(calculator.substitute_holiday?(Date.new(2024, 9, 24))).to be false
        # 日曜日
        expect(calculator.substitute_holiday?(Date.new(2024, 9, 22))).to be false
      end

      it 'returns false when previous day is not Sunday' do
        # 2024年1月2日は火曜日、前日（1月1日）は祝日だが日曜日ではない
        expect(calculator.substitute_holiday?(Date.new(2024, 1, 2))).to be false
      end

      it 'handles edge cases around year boundaries' do
        # 2023年12月31日が日曜日で祝日の場合、2024年1月1日は振替休日になるか？
        # ただし、1月1日は既に元日なので振替休日にはならない
        expect(calculator.substitute_holiday?(Date.new(2024, 1, 1))).to be false
      end
    end

    describe '#holidays_in_year with substitute holidays' do
      let(:holidays_2024) { calculator.holidays_in_year(2024) }

      it 'includes substitute holidays' do
        substitute_holidays = holidays_2024.select { |h| h.type == :substitute }
        expect(substitute_holidays.length).to be >= 1
      end

      it 'includes 振替休日 for 秋分の日 2024' do
        # 2024年9月22日（秋分の日）は日曜日なので、9月23日は振替休日
        substitute_holiday = holidays_2024.find { |h| h.name == "振替休日" && h.date == Date.new(2024, 9, 23) }
        expect(substitute_holiday).not_to be_nil
        expect(substitute_holiday.type).to eq(:substitute)
      end

      it 'does not create substitute holidays when original holiday is not on Sunday' do
        # 2024年1月1日（元日）は月曜日なので振替休日は発生しない
        jan_2_substitute = holidays_2024.find { |h| h.name == "振替休日" && h.date == Date.new(2024, 1, 2) }
        expect(jan_2_substitute).to be_nil
      end

      it 'does not create duplicate substitute holidays' do
        # 振替休日が既存の祝日と重複する場合は作成されない
        substitute_holidays = holidays_2024.select { |h| h.type == :substitute }
        substitute_dates = substitute_holidays.map(&:date)
        
        # 重複がないことを確認
        expect(substitute_dates.uniq.length).to eq(substitute_dates.length)
      end
    end

    describe 'complex substitute holiday scenarios' do
      it 'handles multiple Sunday holidays in a year' do
        # 日曜日に複数の祝日がある年をテスト
        holidays = calculator.holidays_in_year(2024)
        sunday_holidays = holidays.select { |h| h.date.sunday? && h.type != :substitute }
        substitute_holidays = holidays.select { |h| h.type == :substitute }
        
        # 日曜日の祝日の数だけ振替休日があることを確認（重複がない限り）
        expect(substitute_holidays.length).to be <= sunday_holidays.length
      end

      it 'calculates substitute holidays correctly for different years' do
        # 異なる年での振替休日計算をテスト
        [2023, 2024, 2025].each do |year|
          holidays = calculator.holidays_in_year(year)
          substitute_holidays = holidays.select { |h| h.type == :substitute }
          
          substitute_holidays.each do |sub_holiday|
            # 振替休日は月曜日である
            expect(sub_holiday.date.monday?).to be true
            
            # 前日（日曜日）が祝日である
            previous_day = sub_holiday.date - 1
            expect(previous_day.sunday?).to be true
            
            original_holiday = holidays.find { |h| h.date == previous_day && h.type != :substitute }
            expect(original_holiday).not_to be_nil
          end
        end
      end
    end

    describe 'integration with other holiday types' do
      it 'works correctly with fixed holidays on Sunday' do
        # 固定祝日が日曜日の場合の振替休日
        holidays_2023 = calculator.holidays_in_year(2023)
        
        # 2023年2月11日（建国記念の日）は土曜日なので振替休日なし
        feb_12_substitute = holidays_2023.find { |h| h.name == "振替休日" && h.date == Date.new(2023, 2, 12) }
        expect(feb_12_substitute).to be_nil
      end

      it 'works correctly with calculated holidays on Sunday' do
        # 計算祝日（春分の日・秋分の日）が日曜日の場合
        holidays_2024 = calculator.holidays_in_year(2024)
        
        # 2024年9月22日（秋分の日）は日曜日
        autumnal_equinox = holidays_2024.find { |h| h.name == "秋分の日" }
        expect(autumnal_equinox.date.sunday?).to be true
        
        # 翌日の振替休日が存在する
        substitute = holidays_2024.find { |h| h.name == "振替休日" && h.date == Date.new(2024, 9, 23) }
        expect(substitute).not_to be_nil
      end

      it 'works correctly with Happy Monday holidays' do
        # ハッピーマンデー祝日は月曜日なので振替休日は発生しない
        holidays_2024 = calculator.holidays_in_year(2024)
        happy_monday_holidays = holidays_2024.select { |h| h.type == :happy_monday }
        
        happy_monday_holidays.each do |holiday|
          expect(holiday.date.monday?).to be true
          
          # ハッピーマンデー祝日の翌日に振替休日はない
          next_day = holiday.date + 1
          substitute_next_day = holidays_2024.find { |h| h.name == "振替休日" && h.date == next_day }
          expect(substitute_next_day).to be_nil
        end
      end
    end
  end

  describe 'error handling' do
    it 'provides meaningful error messages' do
      expect { calculator.holiday?(123) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Date must be/)
    end

    it 'handles date parsing errors gracefully' do
      expect { calculator.holiday?('not-a-date') }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Invalid date string/)
    end
  end
end