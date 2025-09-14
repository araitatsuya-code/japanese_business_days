# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'RBS Integration Tests' do
  # Manually include extensions for testing
  before(:all) do
    Date.include(JapaneseBusinessDays::DateExtensions) unless Date.method_defined?(:add_business_days)
    Time.include(JapaneseBusinessDays::DateExtensions) unless Time.method_defined?(:add_business_days)
    DateTime.include(JapaneseBusinessDays::DateExtensions) unless DateTime.method_defined?(:add_business_days)
  end

  describe 'Type safety and method signatures' do
    it 'handles all date_like types correctly' do
      date = Date.new(2024, 1, 15) # Monday
      time = Time.new(2024, 1, 15, 12, 0, 0)
      datetime = DateTime.new(2024, 1, 15, 12, 0, 0)
      string = "2024-01-15"

      # Test business_day? with all date_like types
      [date, time, datetime, string].each do |date_like|
        result = JapaneseBusinessDays.business_day?(date_like)
        expect(result).to be_a(TrueClass).or be_a(FalseClass)
      end

      # Test holiday? with all date_like types
      [date, time, datetime, string].each do |date_like|
        result = JapaneseBusinessDays.holiday?(date_like)
        expect(result).to be_a(TrueClass).or be_a(FalseClass)
      end

      # Test business_days_between with all combinations
      [date, time, datetime, string].each do |start_date|
        [date, time, datetime, string].each do |end_date|
          result = JapaneseBusinessDays.business_days_between(start_date, end_date)
          expect(result).to be_a(Integer)
        end
      end
    end

    it 'returns correct types from extension methods' do
      date = Date.new(2024, 1, 15)
      time = Time.new(2024, 1, 15, 12, 0, 0)
      datetime = DateTime.new(2024, 1, 15, 12, 0, 0)

      # Date extensions should return Date
      expect(date.add_business_days(5)).to be_a(Date)
      expect(date.subtract_business_days(3)).to be_a(Date)
      expect(date.next_business_day).to be_a(Date)
      expect(date.previous_business_day).to be_a(Date)

      # Time extensions should return Time
      expect(time.add_business_days(5)).to be_a(Time)
      expect(time.subtract_business_days(3)).to be_a(Time)
      expect(time.next_business_day).to be_a(Time)
      expect(time.previous_business_day).to be_a(Time)

      # DateTime extensions should return DateTime
      expect(datetime.add_business_days(5)).to be_a(DateTime)
      expect(datetime.subtract_business_days(3)).to be_a(DateTime)
      expect(datetime.next_business_day).to be_a(DateTime)
      expect(datetime.previous_business_day).to be_a(DateTime)
    end

    it 'validates holiday_type enum correctly' do
      valid_types = [:fixed, :calculated, :happy_monday, :substitute]
      
      valid_types.each do |type|
        holiday = JapaneseBusinessDays::Holiday.new(Date.today, "Test Holiday", type)
        expect(holiday.type).to eq(type)
      end

      expect {
        JapaneseBusinessDays::Holiday.new(Date.today, "Invalid Holiday", :invalid_type)
      }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
    end

    it 'handles configuration correctly' do
      original_config = JapaneseBusinessDays.configuration

      JapaneseBusinessDays.configure do |config|
        expect(config).to be_a(JapaneseBusinessDays::Configuration)
        
        # Test array setters
        config.additional_holidays = [Date.new(2024, 12, 31)]
        config.additional_business_days = [Date.new(2024, 1, 1)]
        config.weekend_days = [0, 6]
        
        expect(config.additional_holidays).to all(be_a(Date))
        expect(config.additional_business_days).to all(be_a(Date))
        expect(config.weekend_days).to all(be_a(Integer))
      end

      # Reset configuration
      JapaneseBusinessDays.reset_configuration!
    end

    it 'handles error classes with proper inheritance' do
      # Test Error base class
      error = JapaneseBusinessDays::Error.new("test", context: { key: "value" }, suggestions: ["fix it"])
      expect(error).to be_a(StandardError)
      expect(error.context).to be_a(Hash)
      expect(error.suggestions).to be_a(Array)
      expect(error.to_h).to be_a(Hash)

      # Test InvalidDateError
      date_error = JapaneseBusinessDays::InvalidDateError.new("bad date", invalid_date: "invalid")
      expect(date_error).to be_a(JapaneseBusinessDays::Error)
      expect(date_error).to be_a(StandardError)

      # Test InvalidArgumentError
      arg_error = JapaneseBusinessDays::InvalidArgumentError.new("bad arg", parameter_name: "test")
      expect(arg_error).to be_a(JapaneseBusinessDays::Error)
      expect(arg_error).to be_a(StandardError)

      # Test ConfigurationError
      config_error = JapaneseBusinessDays::ConfigurationError.new("bad config", config_key: "test")
      expect(config_error).to be_a(JapaneseBusinessDays::Error)
      expect(config_error).to be_a(StandardError)
    end

    it 'handles cache manager operations correctly' do
      cache_manager = JapaneseBusinessDays::CacheManager.new(max_cache_size: 5)
      
      # Test return types
      expect(cache_manager.cached_holidays_for_year(2024)).to be_nil
      expect(cache_manager.cache_size).to be_a(Integer)
      expect(cache_manager.cached_years).to be_a(Array)
      expect(cache_manager.cache_stats).to be_a(Hash)
      expect(cache_manager.fast_access_available?(2024)).to be_a(TrueClass).or be_a(FalseClass)

      # Test storing and retrieving
      holidays = [JapaneseBusinessDays::Holiday.new(Date.new(2024, 1, 1), "元日", :fixed)]
      cache_manager.store_holidays_for_year(2024, holidays)
      
      cached_holidays = cache_manager.cached_holidays_for_year(2024)
      expect(cached_holidays).to be_a(Array)
      expect(cached_holidays).to all(be_a(JapaneseBusinessDays::Holiday))
    end

    it 'handles logging module correctly' do
      # Test constants
      expect(JapaneseBusinessDays::Logging::LOG_LEVELS).to be_a(Hash)
      expect(JapaneseBusinessDays::Logging::LOG_LEVELS.keys).to all(be_a(Symbol))
      expect(JapaneseBusinessDays::Logging::LOG_LEVELS.values).to all(be_a(Integer))

      # Test level getter/setter
      original_level = JapaneseBusinessDays::Logging.level
      JapaneseBusinessDays::Logging.level = :debug
      expect(JapaneseBusinessDays::Logging.level).to eq(:debug)
      JapaneseBusinessDays::Logging.level = original_level

      # Test logging methods (they should not raise errors)
      expect { JapaneseBusinessDays::Logging.debug("test") }.not_to raise_error
      expect { JapaneseBusinessDays::Logging.info("test") }.not_to raise_error
      expect { JapaneseBusinessDays::Logging.warn("test") }.not_to raise_error
      expect { JapaneseBusinessDays::Logging.error("test") }.not_to raise_error
      
      error = StandardError.new("test error")
      expect { JapaneseBusinessDays::Logging.log_error(error) }.not_to raise_error
    end
  end

  describe 'Complex type interactions' do
    it 'handles nested operations correctly' do
      # Test chaining operations with proper type preservation
      date = Date.new(2024, 1, 15)
      
      # Chain operations and verify types are preserved
      result1 = date.add_business_days(5).subtract_business_days(2)
      expect(result1).to be_a(Date)
      
      result2 = date.next_business_day.add_business_days(3)
      expect(result2).to be_a(Date)
      
      # Test with Time objects
      time = Time.new(2024, 1, 15, 12, 0, 0)
      result3 = time.add_business_days(1).next_business_day
      expect(result3).to be_a(Time)
      expect(result3.hour).to eq(12) # Time components should be preserved
    end

    it 'handles configuration with complex scenarios' do
      JapaneseBusinessDays.configure do |config|
        # Add multiple holidays and business days
        config.add_holiday(Date.new(2024, 12, 30))
        config.add_holiday("2024-12-31")
        config.add_business_day(Date.new(2024, 1, 1)) # Override New Year's Day
        
        # Verify the configuration state
        expect(config.additional_holiday?(Date.new(2024, 12, 30))).to be true
        expect(config.additional_holiday?(Date.new(2024, 12, 31))).to be true
        expect(config.additional_business_day?(Date.new(2024, 1, 1))).to be true
      end

      # Reset for clean state
      JapaneseBusinessDays.reset_configuration!
    end
  end
end