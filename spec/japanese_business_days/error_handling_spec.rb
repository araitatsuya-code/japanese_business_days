# frozen_string_literal: true

require "spec_helper"
require "logger"
require "stringio"

RSpec.describe "Error Handling and Logging" do
  let(:original_log_level) { JapaneseBusinessDays::Logging.level }
  let(:test_logger) { StringIO.new }

  before do
    # テスト用のログ設定
    JapaneseBusinessDays::Logging.level = :debug
    JapaneseBusinessDays::Logging.logger = Logger.new(test_logger)
  end

  after do
    # ログ設定を元に戻す
    JapaneseBusinessDays::Logging.level = original_log_level
    JapaneseBusinessDays::Logging.logger = nil
    JapaneseBusinessDays.reset_configuration!
  end

  describe "Enhanced Error Classes" do
    describe JapaneseBusinessDays::Error do
      it "includes context and suggestions in error message" do
        error = JapaneseBusinessDays::Error.new(
          "Test error",
          context: { method: "test_method", value: 123 },
          suggestions: ["Try this", "Or try that"]
        )

        expect(error.message).to include("Test error")
        expect(error.message).to include("Context: method: test_method, value: 123")
        expect(error.message).to include("Suggestions: 1. Try this; 2. Or try that")
        expect(error.context).to eq({ method: "test_method", value: 123 })
        expect(error.suggestions).to eq(["Try this", "Or try that"])
      end

      it "provides structured error information" do
        error = JapaneseBusinessDays::Error.new(
          "Test error",
          context: { key: "value" },
          suggestions: ["suggestion"]
        )

        error_hash = error.to_h
        expect(error_hash[:error_class]).to eq("JapaneseBusinessDays::Error")
        expect(error_hash[:message]).to include("Test error")
        expect(error_hash[:context]).to eq({ key: "value" })
        expect(error_hash[:suggestions]).to eq(["suggestion"])
        expect(error_hash[:timestamp]).to be_a(String)
      end
    end

    describe JapaneseBusinessDays::InvalidDateError do
      it "provides helpful suggestions for invalid date strings" do
        error = JapaneseBusinessDays::InvalidDateError.new(
          "Invalid date",
          invalid_date: "invalid-date"
        )

        expect(error.suggestions).to include("Use ISO format (YYYY-MM-DD) like '2024-01-01'")
        expect(error.suggestions).to include("Ensure the date string is not empty or blank")
        expect(error.context[:invalid_date]).to eq("invalid-date")
      end

      it "provides helpful suggestions for nil dates" do
        error = JapaneseBusinessDays::InvalidDateError.new(
          "Date is nil",
          invalid_date: nil
        )

        expect(error.suggestions).to include("Provide a non-nil date value")
        expect(error.suggestions).to include("Use Date.today for current date")
      end

      it "provides helpful suggestions for wrong types" do
        error = JapaneseBusinessDays::InvalidDateError.new(
          "Wrong type",
          invalid_date: 123
        )

        expect(error.suggestions).to include("Use Date, Time, DateTime, or String objects")
        expect(error.suggestions).to include("Convert your object to Date using .to_date if available")
      end
    end

    describe JapaneseBusinessDays::InvalidArgumentError do
      it "provides context-specific suggestions for days parameter" do
        error = JapaneseBusinessDays::InvalidArgumentError.new(
          "Invalid days",
          parameter_name: "days",
          received_value: "5"
        )

        expect(error.suggestions).to include("Use positive or negative integers for business days calculation")
        expect(error.context[:parameter_name]).to eq("days")
        expect(error.context[:received_value]).to eq("5")
        expect(error.context[:received_type]).to eq(String)
      end

      it "provides context-specific suggestions for year parameter" do
        error = JapaneseBusinessDays::InvalidArgumentError.new(
          "Invalid year",
          parameter_name: "year",
          received_value: "2024"
        )

        expect(error.suggestions).to include("Use a 4-digit year between 1000 and 9999")
        expect(error.suggestions).to include("Example: holidays_in_year(2024)")
      end

      it "provides context-specific suggestions for date parameters" do
        error = JapaneseBusinessDays::InvalidArgumentError.new(
          "Invalid date",
          parameter_name: "start_date",
          received_value: 123
        )

        expect(error.suggestions).to include("Use Date, Time, DateTime, or String objects")
        expect(error.suggestions).to include("Example: Date.new(2024, 1, 1) or '2024-01-01'")
      end

      it "provides suggestions for nil values" do
        error = JapaneseBusinessDays::InvalidArgumentError.new(
          "Nil value",
          parameter_name: "date",
          received_value: nil
        )

        expect(error.suggestions).to include("Provide a non-nil value for date")
      end
    end

    describe JapaneseBusinessDays::ConfigurationError do
      it "provides configuration-specific suggestions" do
        error = JapaneseBusinessDays::ConfigurationError.new(
          "Invalid config",
          config_key: "additional_holidays",
          config_value: "not an array"
        )

        expect(error.suggestions).to include("Use an array of Date objects")
        expect(error.suggestions).to include("Check the configuration block syntax")
        expect(error.context[:config_key]).to eq("additional_holidays")
      end
    end
  end

  describe "Logging System" do
    describe JapaneseBusinessDays::Logging do
      it "logs messages at different levels" do
        JapaneseBusinessDays::Logging.debug("Debug message")
        JapaneseBusinessDays::Logging.info("Info message")
        JapaneseBusinessDays::Logging.warn("Warning message")
        JapaneseBusinessDays::Logging.error("Error message")

        log_output = test_logger.string
        expect(log_output).to include("DEBUG JapaneseBusinessDays: Debug message")
        expect(log_output).to include("INFO  JapaneseBusinessDays: Info message")
        expect(log_output).to include("WARN  JapaneseBusinessDays: Warning message")
        expect(log_output).to include("ERROR JapaneseBusinessDays: Error message")
      end

      it "includes context information in logs" do
        JapaneseBusinessDays::Logging.info("Test message", { key: "value", number: 123 })

        log_output = test_logger.string
        expect(log_output).to include("Test message")
        expect(log_output).to include('key="value"')
        expect(log_output).to include("number=123")
      end

      it "respects log level settings" do
        JapaneseBusinessDays::Logging.level = :warn

        JapaneseBusinessDays::Logging.debug("Debug message")
        JapaneseBusinessDays::Logging.info("Info message")
        JapaneseBusinessDays::Logging.warn("Warning message")

        log_output = test_logger.string
        expect(log_output).not_to include("Debug message")
        expect(log_output).not_to include("Info message")
        expect(log_output).to include("Warning message")
      end

      it "logs error objects with enhanced information" do
        error = JapaneseBusinessDays::InvalidArgumentError.new(
          "Test error",
          parameter_name: "test_param",
          received_value: "invalid"
        )

        JapaneseBusinessDays::Logging.log_error(error, { method: "test_method" })

        log_output = test_logger.string
        expect(log_output).to include("Test error")
        expect(log_output).to include("method=\"test_method\"")
        expect(log_output).to include("parameter_name=\"test_param\"")
        expect(log_output).to include("error_class=\"JapaneseBusinessDays::InvalidArgumentError\"")
      end

      it "validates log level settings" do
        expect do
          JapaneseBusinessDays::Logging.level = :invalid
        end.to raise_error(ArgumentError, /Invalid log level/)
      end
    end
  end

  describe "Error Handling in Main Module" do
    describe ".configure" do
      it "raises enhanced error when no block is provided" do
        expect do
          JapaneseBusinessDays.configure
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError) do |error|
          expect(error.message).to include("Configuration block is required")
          expect(error.suggestions).to include("Use JapaneseBusinessDays.configure { |config| ... }")
          expect(error.context[:parameter_name]).to eq("block")
        end
      end

      it "logs configuration start and completion" do
        JapaneseBusinessDays.configure do |config|
          config.add_holiday(Date.new(2024, 1, 1))
        end

        log_output = test_logger.string
        expect(log_output).to include("Starting configuration")
        expect(log_output).to include("Configuration completed successfully")
      end

      it "logs and enhances configuration errors" do
        expect do
          JapaneseBusinessDays.configure do |_config|
            raise StandardError, "Test error"
          end
        end.to raise_error(JapaneseBusinessDays::ConfigurationError) do |error|
          expect(error.message).to include("Configuration failed: Test error")
          expect(error.suggestions).to include("Check the configuration block for syntax errors")
        end

        log_output = test_logger.string
        expect(log_output).to include("ERROR")
        expect(log_output).to include("Test error")
      end
    end

    describe ".business_days_between" do
      it "logs calculation details in debug mode" do
        start_date = Date.new(2024, 1, 1)
        end_date = Date.new(2024, 1, 5)

        result = JapaneseBusinessDays.business_days_between(start_date, end_date)

        log_output = test_logger.string
        expect(log_output).to include("Calculating business days between dates")
        expect(log_output).to include("Business days calculation completed")
        expect(log_output).to include("result=#{result}")
      end

      it "logs errors with context information" do
        expect do
          JapaneseBusinessDays.business_days_between(nil, Date.new(2024, 1, 1))
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError)

        log_output = test_logger.string
        expect(log_output).to include("ERROR")
        expect(log_output).to include("start_date cannot be nil")
        expect(log_output).to include("method=\"business_days_between\"")
      end
    end

    describe "validation methods" do
      it "logs validation errors with enhanced context" do
        expect do
          JapaneseBusinessDays.holidays_in_year("2024")
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError) do |error|
          expect(error.context[:parameter_name]).to eq("year")
          expect(error.context[:received_value]).to eq("2024")
          expect(error.context[:expected_type]).to eq(Integer)
        end
      end

      it "logs date parsing errors with helpful context" do
        expect do
          JapaneseBusinessDays.business_day?("invalid-date")
        end.to raise_error(JapaneseBusinessDays::InvalidDateError) do |error|
          expect(error.context[:invalid_date]).to eq("invalid-date")
          expect(error.context).to have_key(:parse_error)
        end
      end
    end
  end

  describe "Error Message Quality" do
    it "provides clear error messages for common mistakes" do
      # nil引数
      expect do
        JapaneseBusinessDays.business_day?(nil)
      end.to raise_error(JapaneseBusinessDays::InvalidArgumentError) do |error|
        expect(error.message).to include("date cannot be nil")
        expect(error.suggestions).to include("Provide a non-nil value for date")
      end

      # 無効な型
      expect do
        JapaneseBusinessDays.add_business_days(Date.today, "5")
      end.to raise_error(JapaneseBusinessDays::InvalidArgumentError) do |error|
        expect(error.message).to include("days must be an Integer")
        expect(error.suggestions).to include("Use positive or negative integers for business days calculation")
      end

      # 無効な年
      expect do
        JapaneseBusinessDays.holidays_in_year(99)
      end.to raise_error(JapaneseBusinessDays::InvalidArgumentError) do |error|
        expect(error.message).to include("Year must be between 1000 and 9999")
        expect(error.context[:valid_range]).to eq("1000-9999")
      end

      # 無効な日付文字列
      expect do
        JapaneseBusinessDays.business_day?("")
      end.to raise_error(JapaneseBusinessDays::InvalidArgumentError) do |error|
        expect(error.message).to include("Date string cannot be empty")
        expect(error.context[:parameter_name]).to eq("date_string")
      end
    end

    it "provides actionable suggestions for fixing errors" do
      error = JapaneseBusinessDays::InvalidArgumentError.new(
        "Invalid parameter",
        parameter_name: "days",
        received_value: 3.14
      )

      expect(error.suggestions).to include("Use positive or negative integers for business days calculation")
      expect(error.suggestions).to include("Example: add_business_days(date, 5) or subtract_business_days(date, 3)")
    end
  end

  describe "Performance Impact" do
    it "does not significantly impact performance when logging is disabled" do
      JapaneseBusinessDays::Logging.level = :error

      start_time = Time.now
      1000.times do
        JapaneseBusinessDays.business_day?(Date.new(2024, 1, 1))
      end
      end_time = Time.now

      # ログが無効な場合、パフォーマンスへの影響は最小限であることを確認
      expect(end_time - start_time).to be < 1.0
    end
  end
end
