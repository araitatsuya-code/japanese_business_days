# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RBS Type Definitions" do
  describe "JapaneseBusinessDays module" do
    it "has VERSION constant as String" do
      expect(JapaneseBusinessDays::VERSION).to be_a(String)
      expect(JapaneseBusinessDays::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end

    it "has FIXED_HOLIDAYS constant as Hash" do
      expect(JapaneseBusinessDays::FIXED_HOLIDAYS).to be_a(Hash)
      expect(JapaneseBusinessDays::FIXED_HOLIDAYS.keys.first).to be_a(Array)
      expect(JapaneseBusinessDays::FIXED_HOLIDAYS.values.first).to be_a(String)
    end

    it "has HAPPY_MONDAY_HOLIDAYS constant as Hash" do
      expect(JapaneseBusinessDays::HAPPY_MONDAY_HOLIDAYS).to be_a(Hash)
      expect(JapaneseBusinessDays::HAPPY_MONDAY_HOLIDAYS.keys.first).to be_a(Array)
      expect(JapaneseBusinessDays::HAPPY_MONDAY_HOLIDAYS.values.first).to be_a(String)
    end

    it "has DEFAULT_WEEKEND_DAYS constant as Array" do
      expect(JapaneseBusinessDays::DEFAULT_WEEKEND_DAYS).to be_a(Array)
      expect(JapaneseBusinessDays::DEFAULT_WEEKEND_DAYS).to all(be_a(Integer))
    end
  end

  describe "Error classes" do
    describe "JapaneseBusinessDays::Error" do
      let(:error) { JapaneseBusinessDays::Error.new("test message", context: { key: "value" }, suggestions: ["suggestion"]) }

      it "has correct attributes" do
        expect(error.context).to be_a(Hash)
        expect(error.suggestions).to be_a(Array)
        expect(error.to_h).to be_a(Hash)
      end

      it "inherits from StandardError" do
        expect(error).to be_a(StandardError)
      end
    end

    describe "JapaneseBusinessDays::InvalidDateError" do
      let(:error) { JapaneseBusinessDays::InvalidDateError.new("invalid date", invalid_date: "bad-date") }

      it "inherits from Error" do
        expect(error).to be_a(JapaneseBusinessDays::Error)
      end

      it "has correct initialization parameters" do
        expect do
          JapaneseBusinessDays::InvalidDateError.new("test", invalid_date: "test",
                                                             expected_format: "YYYY-MM-DD")
        end.not_to raise_error
      end
    end

    describe "JapaneseBusinessDays::InvalidArgumentError" do
      let(:error) { JapaneseBusinessDays::InvalidArgumentError.new("invalid arg", parameter_name: "test") }

      it "inherits from Error" do
        expect(error).to be_a(JapaneseBusinessDays::Error)
      end

      it "has correct initialization parameters" do
        expect do
          JapaneseBusinessDays::InvalidArgumentError.new("test", parameter_name: "param", received_value: 123,
                                                                 expected_type: String)
        end.not_to raise_error
      end
    end

    describe "JapaneseBusinessDays::ConfigurationError" do
      let(:error) { JapaneseBusinessDays::ConfigurationError.new("config error", config_key: "test") }

      it "inherits from Error" do
        expect(error).to be_a(JapaneseBusinessDays::Error)
      end

      it "has correct initialization parameters" do
        expect do
          JapaneseBusinessDays::ConfigurationError.new("test", config_key: "key", config_value: "value")
        end.not_to raise_error
      end
    end
  end

  describe "JapaneseBusinessDays::Logging" do
    it "has LOG_LEVELS constant" do
      expect(JapaneseBusinessDays::Logging::LOG_LEVELS).to be_a(Hash)
      expect(JapaneseBusinessDays::Logging::LOG_LEVELS.keys).to all(be_a(Symbol))
      expect(JapaneseBusinessDays::Logging::LOG_LEVELS.values).to all(be_a(Integer))
    end

    it "has level getter and setter" do
      original_level = JapaneseBusinessDays::Logging.level
      JapaneseBusinessDays::Logging.level = :debug
      expect(JapaneseBusinessDays::Logging.level).to eq(:debug)
      JapaneseBusinessDays::Logging.level = original_level
    end

    it "has logger getter and setter" do
      original_logger = JapaneseBusinessDays::Logging.logger
      test_logger = double("logger")
      JapaneseBusinessDays::Logging.logger = test_logger
      expect(JapaneseBusinessDays::Logging.logger).to eq(test_logger)
      JapaneseBusinessDays::Logging.logger = original_logger
    end

    it "has logging methods" do
      expect(JapaneseBusinessDays::Logging).to respond_to(:debug)
      expect(JapaneseBusinessDays::Logging).to respond_to(:info)
      expect(JapaneseBusinessDays::Logging).to respond_to(:warn)
      expect(JapaneseBusinessDays::Logging).to respond_to(:error)
      expect(JapaneseBusinessDays::Logging).to respond_to(:log_error)
    end
  end

  describe "JapaneseBusinessDays::Holiday" do
    let(:holiday) { JapaneseBusinessDays::Holiday.new(Date.new(2024, 1, 1), "元日", :fixed) }

    it "has correct attributes" do
      expect(holiday.date).to be_a(Date)
      expect(holiday.name).to be_a(String)
      expect(holiday.type).to be_a(Symbol)
    end

    it "has VALID_TYPES constant" do
      expect(JapaneseBusinessDays::Holiday::VALID_TYPES).to be_a(Array)
      expect(JapaneseBusinessDays::Holiday::VALID_TYPES).to all(be_a(Symbol))
    end

    it "has correct methods" do
      expect(holiday.to_s).to be_a(String)
      expect(holiday == holiday).to be(true)
      expect(holiday.eql?(holiday)).to be(true)
      expect(holiday.hash).to be_a(Integer)
    end

    it "validates initialization parameters" do
      expect { JapaneseBusinessDays::Holiday.new("invalid", "name", :fixed) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { JapaneseBusinessDays::Holiday.new(Date.today, "", :fixed) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { JapaneseBusinessDays::Holiday.new(Date.today, "name", :invalid) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
    end
  end

  describe "JapaneseBusinessDays::Configuration" do
    let(:config) { JapaneseBusinessDays::Configuration.new }

    it "has VALID_WEEKDAYS constant" do
      expect(JapaneseBusinessDays::Configuration::VALID_WEEKDAYS).to be_a(Range)
    end

    it "has correct attributes" do
      expect(config.additional_holidays).to be_a(Array)
      expect(config.additional_business_days).to be_a(Array)
      expect(config.weekend_days).to be_a(Array)
    end

    it "has correct methods" do
      expect(config).to respond_to(:additional_holidays=)
      expect(config).to respond_to(:additional_business_days=)
      expect(config).to respond_to(:weekend_days=)
      expect(config).to respond_to(:add_holiday)
      expect(config).to respond_to(:add_business_day)
      expect(config).to respond_to(:additional_holiday?)
      expect(config).to respond_to(:additional_business_day?)
      expect(config).to respond_to(:weekend_day?)
      expect(config).to respond_to(:reset!)
    end

    it "validates setter parameters" do
      expect { config.additional_holidays = "invalid" }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { config.additional_business_days = "invalid" }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { config.weekend_days = "invalid" }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
    end

    it "validates method parameters" do
      expect { config.add_holiday(nil) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { config.add_business_day(nil) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
    end
  end

  describe "JapaneseBusinessDays::CacheManager" do
    let(:cache_manager) { JapaneseBusinessDays::CacheManager.new }

    it "has DEFAULT_MAX_CACHE_SIZE constant" do
      expect(JapaneseBusinessDays::CacheManager::DEFAULT_MAX_CACHE_SIZE).to be_a(Integer)
    end

    it "has correct methods" do
      expect(cache_manager).to respond_to(:cached_holidays_for_year)
      expect(cache_manager).to respond_to(:store_holidays_for_year)
      expect(cache_manager).to respond_to(:clear_cache)
      expect(cache_manager).to respond_to(:clear_cache_for_year)
      expect(cache_manager).to respond_to(:cache_size)
      expect(cache_manager).to respond_to(:cached_years)
      expect(cache_manager).to respond_to(:cache_stats)
      expect(cache_manager).to respond_to(:fast_access_available?)
    end

    it "returns correct types" do
      expect(cache_manager.cached_holidays_for_year(2024)).to be_nil
      expect(cache_manager.cache_size).to be_a(Integer)
      expect(cache_manager.cached_years).to be_a(Array)
      expect(cache_manager.cache_stats).to be_a(Hash)
      expect(cache_manager.fast_access_available?(2024)).to be_a(TrueClass).or be_a(FalseClass)
    end

    it "validates parameters" do
      expect { cache_manager.cached_holidays_for_year("invalid") }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { cache_manager.store_holidays_for_year("invalid", []) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { cache_manager.clear_cache_for_year("invalid") }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
    end
  end

  describe "JapaneseBusinessDays::HolidayCalculator" do
    let(:calculator) { JapaneseBusinessDays::HolidayCalculator.new }

    it "has constants" do
      expect(JapaneseBusinessDays::HolidayCalculator::FIXED_HOLIDAYS).to be_a(Hash)
      expect(JapaneseBusinessDays::HolidayCalculator::HAPPY_MONDAY_HOLIDAYS).to be_a(Hash)
    end

    it "has correct methods" do
      expect(calculator).to respond_to(:holiday?)
      expect(calculator).to respond_to(:holidays_in_year)
      expect(calculator).to respond_to(:substitute_holiday?)
    end

    it "returns correct types" do
      date = Date.new(2024, 1, 1)
      expect(calculator.holiday?(date)).to be_a(TrueClass).or be_a(FalseClass)
      expect(calculator.holidays_in_year(2024)).to be_a(Array)
      expect(calculator.holidays_in_year(2024)).to all(be_a(JapaneseBusinessDays::Holiday))
      expect(calculator.substitute_holiday?(date)).to be_a(TrueClass).or be_a(FalseClass)
    end

    it "validates parameters" do
      expect { calculator.holiday?("invalid") }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { calculator.holidays_in_year("invalid") }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { calculator.substitute_holiday?("invalid") }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
    end
  end

  describe "JapaneseBusinessDays::BusinessDayCalculator" do
    let(:holiday_calculator) { JapaneseBusinessDays::HolidayCalculator.new }
    let(:configuration) { JapaneseBusinessDays::Configuration.new }
    let(:calculator) { JapaneseBusinessDays::BusinessDayCalculator.new(holiday_calculator, configuration) }

    it "has correct methods" do
      expect(calculator).to respond_to(:business_day?)
      expect(calculator).to respond_to(:business_days_between)
      expect(calculator).to respond_to(:add_business_days)
      expect(calculator).to respond_to(:subtract_business_days)
      expect(calculator).to respond_to(:next_business_day)
      expect(calculator).to respond_to(:previous_business_day)
    end

    it "returns correct types" do
      date = Date.new(2024, 1, 1)
      expect(calculator.business_day?(date)).to be_a(TrueClass).or be_a(FalseClass)
      expect(calculator.business_days_between(date, date + 7)).to be_a(Integer)
      expect(calculator.add_business_days(date, 5)).to be_a(Date)
      expect(calculator.subtract_business_days(date, 5)).to be_a(Date)
      expect(calculator.next_business_day(date)).to be_a(Date)
      expect(calculator.previous_business_day(date)).to be_a(Date)
    end

    it "validates parameters" do
      expect { calculator.business_day?("invalid") }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { calculator.business_days_between("invalid", Date.today) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { calculator.add_business_days("invalid", 5) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { calculator.add_business_days(Date.today, "invalid") }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
    end
  end

  describe "JapaneseBusinessDays module methods" do
    it "has configuration method" do
      expect(JapaneseBusinessDays.configuration).to be_a(JapaneseBusinessDays::Configuration)
    end

    it "has configure method" do
      expect { JapaneseBusinessDays.configure { |config| } }.not_to raise_error
      expect { JapaneseBusinessDays.configure }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
    end

    it "has business calculation methods" do
      date = Date.new(2024, 1, 1)
      expect(JapaneseBusinessDays.business_days_between(date, date + 7)).to be_a(Integer)
      expect(JapaneseBusinessDays.business_day?(date)).to be_a(TrueClass).or be_a(FalseClass)
      expect(JapaneseBusinessDays.holiday?(date)).to be_a(TrueClass).or be_a(FalseClass)
      expect(JapaneseBusinessDays.holidays_in_year(2024)).to be_a(Array)
      expect(JapaneseBusinessDays.add_business_days(date, 5)).to be_a(Date)
      expect(JapaneseBusinessDays.subtract_business_days(date, 5)).to be_a(Date)
      expect(JapaneseBusinessDays.next_business_day(date)).to be_a(Date)
      expect(JapaneseBusinessDays.previous_business_day(date)).to be_a(Date)
    end

    it "validates parameters" do
      expect { JapaneseBusinessDays.business_days_between(nil, Date.today) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { JapaneseBusinessDays.business_day?(nil) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { JapaneseBusinessDays.holiday?(nil) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { JapaneseBusinessDays.holidays_in_year(nil) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
    end
  end

  describe "JapaneseBusinessDays::DateExtensions" do
    # Manually include extensions for testing since they're only auto-loaded in Rails
    before(:all) do
      Date.include(JapaneseBusinessDays::DateExtensions) unless Date.method_defined?(:add_business_days)
      Time.include(JapaneseBusinessDays::DateExtensions) unless Time.method_defined?(:add_business_days)
      DateTime.include(JapaneseBusinessDays::DateExtensions) unless DateTime.method_defined?(:add_business_days)
    end

    let(:date) { Date.new(2024, 1, 1) }
    let(:time) { Time.new(2024, 1, 1, 12, 0, 0) }
    let(:datetime) { DateTime.new(2024, 1, 1, 12, 0, 0) }

    it "extends Date class" do
      expect(date).to respond_to(:add_business_days)
      expect(date).to respond_to(:subtract_business_days)
      expect(date).to respond_to(:business_day?)
      expect(date).to respond_to(:holiday?)
      expect(date).to respond_to(:next_business_day)
      expect(date).to respond_to(:previous_business_day)
    end

    it "extends Time class" do
      expect(time).to respond_to(:add_business_days)
      expect(time).to respond_to(:subtract_business_days)
      expect(time).to respond_to(:business_day?)
      expect(time).to respond_to(:holiday?)
      expect(time).to respond_to(:next_business_day)
      expect(time).to respond_to(:previous_business_day)
    end

    it "extends DateTime class" do
      expect(datetime).to respond_to(:add_business_days)
      expect(datetime).to respond_to(:subtract_business_days)
      expect(datetime).to respond_to(:business_day?)
      expect(datetime).to respond_to(:holiday?)
      expect(datetime).to respond_to(:next_business_day)
      expect(datetime).to respond_to(:previous_business_day)
    end

    it "returns correct types for Date" do
      expect(date.add_business_days(5)).to be_a(Date)
      expect(date.subtract_business_days(5)).to be_a(Date)
      expect(date.business_day?).to be_a(TrueClass).or be_a(FalseClass)
      expect(date.holiday?).to be_a(TrueClass).or be_a(FalseClass)
      expect(date.next_business_day).to be_a(Date)
      expect(date.previous_business_day).to be_a(Date)
    end

    it "returns correct types for Time" do
      expect(time.add_business_days(5)).to be_a(Time)
      expect(time.subtract_business_days(5)).to be_a(Time)
      expect(time.business_day?).to be_a(TrueClass).or be_a(FalseClass)
      expect(time.holiday?).to be_a(TrueClass).or be_a(FalseClass)
      expect(time.next_business_day).to be_a(Time)
      expect(time.previous_business_day).to be_a(Time)
    end

    it "returns correct types for DateTime" do
      expect(datetime.add_business_days(5)).to be_a(DateTime)
      expect(datetime.subtract_business_days(5)).to be_a(DateTime)
      expect(datetime.business_day?).to be_a(TrueClass).or be_a(FalseClass)
      expect(datetime.holiday?).to be_a(TrueClass).or be_a(FalseClass)
      expect(datetime.next_business_day).to be_a(DateTime)
      expect(datetime.previous_business_day).to be_a(DateTime)
    end

    it "validates parameters" do
      expect { date.add_business_days(nil) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { date.add_business_days("invalid") }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { date.subtract_business_days(nil) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      expect { date.subtract_business_days("invalid") }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
    end
  end

  describe "Type compatibility" do
    it "accepts date_like types for main module methods" do
      date = Date.new(2024, 1, 1)
      time = Time.new(2024, 1, 1, 12, 0, 0)
      datetime = DateTime.new(2024, 1, 1, 12, 0, 0)
      string = "2024-01-01"

      [date, time, datetime, string].each do |date_like|
        expect { JapaneseBusinessDays.business_day?(date_like) }.not_to raise_error
        expect { JapaneseBusinessDays.holiday?(date_like) }.not_to raise_error
        expect { JapaneseBusinessDays.add_business_days(date_like, 5) }.not_to raise_error
        expect { JapaneseBusinessDays.subtract_business_days(date_like, 5) }.not_to raise_error
        expect { JapaneseBusinessDays.next_business_day(date_like) }.not_to raise_error
        expect { JapaneseBusinessDays.previous_business_day(date_like) }.not_to raise_error
      end

      [date, time, datetime, string].each do |start_date|
        [date, time, datetime, string].each do |end_date|
          expect { JapaneseBusinessDays.business_days_between(start_date, end_date) }.not_to raise_error
        end
      end
    end

    it "accepts holiday_type symbols" do
      valid_types = %i[fixed calculated happy_monday substitute]
      valid_types.each do |type|
        expect { JapaneseBusinessDays::Holiday.new(Date.today, "Test Holiday", type) }.not_to raise_error
      end

      expect { JapaneseBusinessDays::Holiday.new(Date.today, "Test Holiday", :invalid) }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
    end
  end
end
