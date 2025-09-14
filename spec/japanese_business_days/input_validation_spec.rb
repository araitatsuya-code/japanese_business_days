# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JapaneseBusinessDays, 'Input Validation' do
  before do
    # 各テスト前に設定をリセット
    JapaneseBusinessDays.reset_configuration!
    
    # DateExtensionsを手動で追加（テスト環境ではRailsが検出されないため）
    Date.include(JapaneseBusinessDays::DateExtensions) unless Date.include?(JapaneseBusinessDays::DateExtensions)
    Time.include(JapaneseBusinessDays::DateExtensions) unless Time.include?(JapaneseBusinessDays::DateExtensions)
    DateTime.include(JapaneseBusinessDays::DateExtensions) unless DateTime.include?(JapaneseBusinessDays::DateExtensions)
  end

  describe 'nil argument validation' do
    describe '.business_days_between' do
      it 'raises InvalidArgumentError when start_date is nil' do
        expect {
          JapaneseBusinessDays.business_days_between(nil, Date.new(2024, 1, 10))
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "start_date cannot be nil")
      end

      it 'raises InvalidArgumentError when end_date is nil' do
        expect {
          JapaneseBusinessDays.business_days_between(Date.new(2024, 1, 1), nil)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "end_date cannot be nil")
      end

      it 'raises InvalidArgumentError when both dates are nil' do
        expect {
          JapaneseBusinessDays.business_days_between(nil, nil)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "start_date cannot be nil")
      end
    end

    describe '.business_day?' do
      it 'raises InvalidArgumentError when date is nil' do
        expect {
          JapaneseBusinessDays.business_day?(nil)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "date cannot be nil")
      end
    end

    describe '.holiday?' do
      it 'raises InvalidArgumentError when date is nil' do
        expect {
          JapaneseBusinessDays.holiday?(nil)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "date cannot be nil")
      end
    end

    describe '.holidays_in_year' do
      it 'raises InvalidArgumentError when year is nil' do
        expect {
          JapaneseBusinessDays.holidays_in_year(nil)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "year cannot be nil")
      end
    end

    describe '.add_business_days' do
      it 'raises InvalidArgumentError when date is nil' do
        expect {
          JapaneseBusinessDays.add_business_days(nil, 5)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "date cannot be nil")
      end

      it 'raises InvalidArgumentError when days is nil' do
        expect {
          JapaneseBusinessDays.add_business_days(Date.new(2024, 1, 1), nil)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "days cannot be nil")
      end
    end

    describe '.subtract_business_days' do
      it 'raises InvalidArgumentError when date is nil' do
        expect {
          JapaneseBusinessDays.subtract_business_days(nil, 5)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "date cannot be nil")
      end

      it 'raises InvalidArgumentError when days is nil' do
        expect {
          JapaneseBusinessDays.subtract_business_days(Date.new(2024, 1, 1), nil)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "days cannot be nil")
      end
    end

    describe '.next_business_day' do
      it 'raises InvalidArgumentError when date is nil' do
        expect {
          JapaneseBusinessDays.next_business_day(nil)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "date cannot be nil")
      end
    end

    describe '.previous_business_day' do
      it 'raises InvalidArgumentError when date is nil' do
        expect {
          JapaneseBusinessDays.previous_business_day(nil)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "date cannot be nil")
      end
    end
  end

  describe 'invalid type validation' do
    describe 'date parameters' do
      let(:invalid_date_types) { [123, 45.67, [], {}, Object.new, true, false] }

      describe '.business_days_between' do
        it 'raises InvalidArgumentError for invalid start_date types' do
          invalid_date_types.each do |invalid_date|
            expect {
              JapaneseBusinessDays.business_days_between(invalid_date, Date.new(2024, 1, 10))
            }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Invalid date type/)
          end
        end

        it 'raises InvalidArgumentError for invalid end_date types' do
          invalid_date_types.each do |invalid_date|
            expect {
              JapaneseBusinessDays.business_days_between(Date.new(2024, 1, 1), invalid_date)
            }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Invalid date type/)
          end
        end
      end

      describe '.business_day?' do
        it 'raises InvalidArgumentError for invalid date types' do
          invalid_date_types.each do |invalid_date|
            expect {
              JapaneseBusinessDays.business_day?(invalid_date)
            }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Invalid date type/)
          end
        end
      end

      describe '.holiday?' do
        it 'raises InvalidArgumentError for invalid date types' do
          invalid_date_types.each do |invalid_date|
            expect {
              JapaneseBusinessDays.holiday?(invalid_date)
            }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Invalid date type/)
          end
        end
      end
    end

    describe 'integer parameters' do
      let(:invalid_integer_types) { ["5", 5.5, [], {}, Object.new, true, false] }

      describe '.holidays_in_year' do
        it 'raises InvalidArgumentError for invalid year types' do
          invalid_integer_types.each do |invalid_year|
            expect {
              JapaneseBusinessDays.holidays_in_year(invalid_year)
            }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /must be an Integer/)
          end
        end
      end

      describe '.add_business_days' do
        it 'raises InvalidArgumentError for invalid days types' do
          invalid_integer_types.each do |invalid_days|
            expect {
              JapaneseBusinessDays.add_business_days(Date.new(2024, 1, 1), invalid_days)
            }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /must be an Integer/)
          end
        end
      end

      describe '.subtract_business_days' do
        it 'raises InvalidArgumentError for invalid days types' do
          invalid_integer_types.each do |invalid_days|
            expect {
              JapaneseBusinessDays.subtract_business_days(Date.new(2024, 1, 1), invalid_days)
            }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /must be an Integer/)
          end
        end
      end
    end
  end

  describe 'invalid date format validation' do
    let(:empty_strings) { ["", "   "] }
    let(:invalid_date_strings) { 
      [
        "invalid",    # 無効な形式
        "2024-13-01", # 無効な月
        "2024-02-30", # 無効な日
        "not-a-date", # 完全に無効
        "2024/2/30",  # 存在しない日付
      ]
    }

    describe '.business_days_between' do
      it 'raises InvalidArgumentError for empty date strings' do
        empty_strings.each do |empty_string|
          expect {
            JapaneseBusinessDays.business_days_between(empty_string, Date.new(2024, 1, 10))
          }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Date string cannot be/)
        end
      end

      it 'raises InvalidDateError for invalid date strings' do
        invalid_date_strings.each do |invalid_string|
          expect {
            JapaneseBusinessDays.business_days_between(invalid_string, Date.new(2024, 1, 10))
          }.to raise_error(JapaneseBusinessDays::InvalidDateError, /Invalid date/)
        end
      end
    end

    describe '.business_day?' do
      it 'raises InvalidArgumentError for empty date strings' do
        empty_strings.each do |empty_string|
          expect {
            JapaneseBusinessDays.business_day?(empty_string)
          }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Date string cannot be/)
        end
      end

      it 'raises InvalidDateError for invalid date strings' do
        invalid_date_strings.each do |invalid_string|
          expect {
            JapaneseBusinessDays.business_day?(invalid_string)
          }.to raise_error(JapaneseBusinessDays::InvalidDateError, /Invalid date/)
        end
      end
    end

    describe '.holiday?' do
      it 'raises InvalidArgumentError for empty date strings' do
        empty_strings.each do |empty_string|
          expect {
            JapaneseBusinessDays.holiday?(empty_string)
          }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Date string cannot be/)
        end
      end

      it 'raises InvalidDateError for invalid date strings' do
        invalid_date_strings.each do |invalid_string|
          expect {
            JapaneseBusinessDays.holiday?(invalid_string)
          }.to raise_error(JapaneseBusinessDays::InvalidDateError, /Invalid date/)
        end
      end
    end
  end

  describe 'year range validation' do
    describe '.holidays_in_year' do
      it 'raises InvalidArgumentError for year below 1000' do
        expect {
          JapaneseBusinessDays.holidays_in_year(999)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "Year must be between 1000 and 9999, got 999")
      end

      it 'raises InvalidArgumentError for year above 9999' do
        expect {
          JapaneseBusinessDays.holidays_in_year(10000)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "Year must be between 1000 and 9999, got 10000")
      end

      it 'accepts valid years' do
        expect { JapaneseBusinessDays.holidays_in_year(1000) }.not_to raise_error
        expect { JapaneseBusinessDays.holidays_in_year(2024) }.not_to raise_error
        expect { JapaneseBusinessDays.holidays_in_year(2030) }.not_to raise_error
      end
    end
  end

  describe 'configuration validation' do
    describe '.configure' do
      it 'raises InvalidArgumentError when no block is given' do
        expect {
          JapaneseBusinessDays.configure
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "Configuration block is required")
      end

      it 'wraps configuration errors in ConfigurationError' do
        expect {
          JapaneseBusinessDays.configure do |config|
            # 標準エラーを発生させる（InvalidArgumentError以外）
            raise StandardError, "Some unexpected error"
          end
        }.to raise_error(JapaneseBusinessDays::ConfigurationError, /Configuration error/)
      end

      it 'preserves InvalidArgumentError from configuration methods' do
        expect {
          JapaneseBusinessDays.configure do |config|
            config.weekend_days = "invalid"
          end
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /weekend_days must be an Array/)
      end

      it 'preserves InvalidArgumentError from configuration' do
        expect {
          JapaneseBusinessDays.configure do |config|
            config.add_holiday(nil)
          end
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "date cannot be nil")
      end
    end
  end

  describe 'DateExtensions validation' do
    let(:date) { Date.new(2024, 1, 15) }

    describe '#add_business_days' do
      it 'raises InvalidArgumentError when days is nil' do
        expect {
          date.add_business_days(nil)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "days cannot be nil")
      end

      it 'raises InvalidArgumentError for invalid days types' do
        ["5", 5.5, [], {}].each do |invalid_days|
          expect {
            date.add_business_days(invalid_days)
          }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /must be an Integer/)
        end
      end
    end

    describe '#subtract_business_days' do
      it 'raises InvalidArgumentError when days is nil' do
        expect {
          date.subtract_business_days(nil)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "days cannot be nil")
      end

      it 'raises InvalidArgumentError for invalid days types' do
        ["5", 5.5, [], {}].each do |invalid_days|
          expect {
            date.subtract_business_days(invalid_days)
          }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /must be an Integer/)
        end
      end
    end
  end

  describe 'Configuration class validation' do
    let(:config) { JapaneseBusinessDays::Configuration.new }

    describe '#add_holiday' do
      it 'raises InvalidArgumentError when date is nil' do
        expect {
          config.add_holiday(nil)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "date cannot be nil")
      end

      it 'raises InvalidArgumentError for invalid date types' do
        [123, [], {}].each do |invalid_date|
          expect {
            config.add_holiday(invalid_date)
          }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Invalid date type/)
        end
      end

      it 'raises InvalidArgumentError for empty date strings' do
        expect {
          config.add_holiday("")
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "Date string cannot be empty")
      end

      it 'raises InvalidDateError for invalid date format strings' do
        expect {
          config.add_holiday("invalid-date")
        }.to raise_error(JapaneseBusinessDays::InvalidDateError, /Invalid date format/)
      end
    end

    describe '#add_business_day' do
      it 'raises InvalidArgumentError when date is nil' do
        expect {
          config.add_business_day(nil)
        }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, "date cannot be nil")
      end

      it 'raises InvalidArgumentError for invalid date types' do
        [123, [], {}].each do |invalid_date|
          expect {
            config.add_business_day(invalid_date)
          }.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Invalid date type/)
        end
      end
    end
  end

  describe 'valid input acceptance' do
    let(:valid_dates) {
      [
        Date.new(2024, 1, 15),
        Time.new(2024, 1, 15, 12, 0, 0),
        DateTime.new(2024, 1, 15, 12, 0, 0),
        "2024-01-15",
        "2024/01/15",
        "Jan 15, 2024"
      ]
    }

    it 'accepts all valid date formats' do
      valid_dates.each do |valid_date|
        expect { JapaneseBusinessDays.business_day?(valid_date) }.not_to raise_error
        expect { JapaneseBusinessDays.holiday?(valid_date) }.not_to raise_error
        expect { JapaneseBusinessDays.next_business_day(valid_date) }.not_to raise_error
        expect { JapaneseBusinessDays.previous_business_day(valid_date) }.not_to raise_error
      end
    end

    it 'accepts valid integer values for days and years' do
      expect { JapaneseBusinessDays.add_business_days(Date.new(2024, 1, 15), 5) }.not_to raise_error
      expect { JapaneseBusinessDays.add_business_days(Date.new(2024, 1, 15), -5) }.not_to raise_error
      expect { JapaneseBusinessDays.add_business_days(Date.new(2024, 1, 15), 0) }.not_to raise_error
      expect { JapaneseBusinessDays.holidays_in_year(2024) }.not_to raise_error
    end
  end
end