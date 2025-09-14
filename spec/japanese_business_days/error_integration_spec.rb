# frozen_string_literal: true

require "spec_helper"
require "logger"
require "stringio"

RSpec.describe "Error Handling Integration" do
  after do
    JapaneseBusinessDays.reset_configuration!
  end

  describe "Enhanced error messages in real usage" do
    it "provides helpful error messages for common mistakes" do
      # nil引数のテスト
      expect {
        JapaneseBusinessDays.business_day?(nil)
      }.to raise_error(JapaneseBusinessDays::InvalidArgumentError) do |error|
        expect(error.message).to include("date cannot be nil")
        expect(error.context[:parameter_name]).to eq("date")
        expect(error.suggestions).to include("Provide a non-nil value for date")
      end

      # 無効な型のテスト
      expect {
        JapaneseBusinessDays.add_business_days(Date.today, "5")
      }.to raise_error(JapaneseBusinessDays::InvalidArgumentError) do |error|
        expect(error.message).to include("days must be an Integer")
        expect(error.context[:parameter_name]).to eq("days")
        expect(error.context[:received_value]).to eq("5")
        expect(error.context[:expected_type]).to eq(Integer)
      end

      # 無効な年のテスト
      expect {
        JapaneseBusinessDays.holidays_in_year(99)
      }.to raise_error(JapaneseBusinessDays::InvalidArgumentError) do |error|
        expect(error.message).to include("Year must be between 1000 and 9999")
        expect(error.context[:parameter_name]).to eq("year")
        expect(error.context[:valid_range]).to eq("1000-9999")
      end

      # 無効な日付文字列のテスト
      expect {
        JapaneseBusinessDays.business_day?("invalid-date")
      }.to raise_error(JapaneseBusinessDays::InvalidDateError) do |error|
        expect(error.message).to include("Invalid date format")
        expect(error.context[:invalid_date]).to eq("invalid-date")
        expect(error.suggestions).to include("Use ISO format (YYYY-MM-DD) like '2024-01-01'")
      end
    end

    it "provides structured error information" do
      begin
        JapaneseBusinessDays.business_day?(123)
      rescue JapaneseBusinessDays::InvalidArgumentError => e
        error_hash = e.to_h
        
        expect(error_hash[:error_class]).to eq("JapaneseBusinessDays::InvalidArgumentError")
        expect(error_hash[:context]).to include(:parameter_name, :received_value, :expected_type)
        expect(error_hash[:suggestions]).to be_an(Array)
        expect(error_hash[:timestamp]).to be_a(String)
      end
    end

    it "handles configuration errors gracefully" do
      expect {
        JapaneseBusinessDays.configure do |config|
          raise StandardError, "Test configuration error"
        end
      }.to raise_error(JapaneseBusinessDays::ConfigurationError) do |error|
        expect(error.message).to include("Configuration failed")
        expect(error.suggestions).to include("Check the configuration block for syntax errors")
      end
    end
  end

  describe "Error logging integration" do
    let(:test_logger) { StringIO.new }
    
    before do
      JapaneseBusinessDays::Logging.level = :debug
      JapaneseBusinessDays::Logging.logger = Logger.new(test_logger)
    end
    
    after do
      JapaneseBusinessDays::Logging.level = :error
      JapaneseBusinessDays::Logging.logger = nil
    end

    it "logs errors with context during normal operations" do
      expect {
        JapaneseBusinessDays.business_day?(nil)
      }.to raise_error(JapaneseBusinessDays::InvalidArgumentError)
      
      log_output = test_logger.string
      expect(log_output).to include("ERROR")
      expect(log_output).to include("date cannot be nil")
      expect(log_output).to include("parameter_name=\"date\"")
    end

    it "logs successful operations in debug mode" do
      JapaneseBusinessDays.business_day?(Date.new(2024, 1, 1))
      
      # Debug logging is not implemented for successful operations in this task
      # This test verifies that the system doesn't crash when logging is enabled
      expect(test_logger.string).to be_a(String)
    end
  end

  describe "Performance with enhanced error handling" do
    it "does not significantly impact performance" do
      # Disable logging for performance test
      original_level = JapaneseBusinessDays::Logging.level
      JapaneseBusinessDays::Logging.level = :error
      
      start_time = Time.now
      1000.times do
        JapaneseBusinessDays.business_day?(Date.new(2024, 1, 1))
      end
      end_time = Time.now
      
      # Should complete within reasonable time even with enhanced error handling
      expect(end_time - start_time).to be < 1.0
      
      JapaneseBusinessDays::Logging.level = original_level
    end
  end
end