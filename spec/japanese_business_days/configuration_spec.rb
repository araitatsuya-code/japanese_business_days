# frozen_string_literal: true

require "spec_helper"
require "date"

RSpec.describe JapaneseBusinessDays::Configuration do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.additional_holidays).to eq([])
      expect(config.additional_business_days).to eq([])
      expect(config.weekend_days).to eq([0, 6])
    end
  end

  describe "#additional_holidays=" do
    context "with valid date array" do
      it "sets additional holidays" do
        dates = [Date.new(2024, 12, 31), Date.new(2024, 12, 30)]
        config.additional_holidays = dates

        expect(config.additional_holidays).to eq(dates)
        expect(config.additional_holidays).not_to be(dates) # should be a copy
      end

      it "accepts empty array" do
        config.additional_holidays = []
        expect(config.additional_holidays).to eq([])
      end
    end

    context "with invalid input" do
      it "raises InvalidArgumentError for non-array" do
        expect do
          config.additional_holidays = "not an array"
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /additional_holidays must be an Array/)
      end

      it "raises InvalidArgumentError for array with non-Date objects" do
        expect do
          config.additional_holidays = [Date.new(2024, 1, 1), "2024-01-02"]
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /additional_holidays\[1\] must be a Date object/)
      end

      it "raises InvalidArgumentError for nil" do
        expect do
          config.additional_holidays = nil
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /additional_holidays must be an Array/)
      end
    end
  end

  describe "#additional_business_days=" do
    context "with valid date array" do
      it "sets additional business days" do
        dates = [Date.new(2024, 1, 1), Date.new(2024, 5, 3)]
        config.additional_business_days = dates

        expect(config.additional_business_days).to eq(dates)
        expect(config.additional_business_days).not_to be(dates) # should be a copy
      end

      it "accepts empty array" do
        config.additional_business_days = []
        expect(config.additional_business_days).to eq([])
      end
    end

    context "with invalid input" do
      it "raises InvalidArgumentError for non-array" do
        expect do
          config.additional_business_days = 123
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /additional_business_days must be an Array/)
      end

      it "raises InvalidArgumentError for array with non-Date objects" do
        expect do
          config.additional_business_days = [Date.new(2024, 1, 1), Time.now]
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError,
                           /additional_business_days\[1\] must be a Date object/)
      end
    end
  end

  describe "#weekend_days=" do
    context "with valid weekday array" do
      it "sets weekend days" do
        days = [5, 6] # Friday and Saturday
        config.weekend_days = days

        expect(config.weekend_days).to eq(days)
        expect(config.weekend_days).not_to be(days) # should be a copy
      end

      it "accepts single weekend day" do
        config.weekend_days = [0] # Sunday only
        expect(config.weekend_days).to eq([0])
      end

      it "accepts all weekdays as weekend" do
        config.weekend_days = [0, 1, 2, 3, 4, 5, 6]
        expect(config.weekend_days).to eq([0, 1, 2, 3, 4, 5, 6])
      end
    end

    context "with invalid input" do
      it "raises InvalidArgumentError for non-array" do
        expect do
          config.weekend_days = 6
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /weekend_days must be an Array/)
      end

      it "raises InvalidArgumentError for empty array" do
        expect do
          config.weekend_days = []
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /weekend_days cannot be empty/)
      end

      it "raises InvalidArgumentError for invalid weekday numbers" do
        expect do
          config.weekend_days = [0, 7] # 7 is invalid
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError,
                           /weekend_days\[1\] must be an integer between 0-6/)
      end

      it "raises InvalidArgumentError for negative numbers" do
        expect do
          config.weekend_days = [-1, 0]
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError,
                           /weekend_days\[0\] must be an integer between 0-6/)
      end

      it "raises InvalidArgumentError for non-integer values" do
        expect do
          config.weekend_days = [0, "6"]
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError,
                           /weekend_days\[1\] must be an integer between 0-6/)
      end

      it "raises InvalidArgumentError for duplicate values" do
        expect do
          config.weekend_days = [0, 6, 0]
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /weekend_days cannot contain duplicate values/)
      end
    end
  end

  describe "#add_holiday" do
    context "with valid date inputs" do
      it "adds Date object to additional holidays" do
        date = Date.new(2024, 12, 31)
        config.add_holiday(date)

        expect(config.additional_holidays).to include(date)
      end

      it "adds Time object as Date to additional holidays" do
        time = Time.new(2024, 12, 31, 10, 30, 0)
        config.add_holiday(time)

        expect(config.additional_holidays).to include(Date.new(2024, 12, 31))
      end

      it "adds DateTime object as Date to additional holidays" do
        datetime = DateTime.new(2024, 12, 31, 10, 30, 0)
        config.add_holiday(datetime)

        expect(config.additional_holidays).to include(Date.new(2024, 12, 31))
      end

      it "adds String date to additional holidays" do
        config.add_holiday("2024-12-31")

        expect(config.additional_holidays).to include(Date.new(2024, 12, 31))
      end

      it "does not add duplicate dates" do
        date = Date.new(2024, 12, 31)
        config.add_holiday(date)
        config.add_holiday(date)

        expect(config.additional_holidays.count(date)).to eq(1)
      end
    end

    context "with invalid inputs" do
      it "raises InvalidArgumentError for invalid type" do
        expect do
          config.add_holiday(123)
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Invalid date type/)
      end

      it "raises InvalidDateError for invalid string format" do
        expect do
          config.add_holiday("invalid-date")
        end.to raise_error(JapaneseBusinessDays::InvalidDateError, /Invalid date format/)
      end
    end
  end

  describe "#add_business_day" do
    context "with valid date inputs" do
      it "adds Date object to additional business days" do
        date = Date.new(2024, 1, 1) # New Year's Day (normally a holiday)
        config.add_business_day(date)

        expect(config.additional_business_days).to include(date)
      end

      it "adds Time object as Date to additional business days" do
        time = Time.new(2024, 1, 1, 10, 30, 0)
        config.add_business_day(time)

        expect(config.additional_business_days).to include(Date.new(2024, 1, 1))
      end

      it "adds String date to additional business days" do
        config.add_business_day("2024-01-01")

        expect(config.additional_business_days).to include(Date.new(2024, 1, 1))
      end

      it "does not add duplicate dates" do
        date = Date.new(2024, 1, 1)
        config.add_business_day(date)
        config.add_business_day(date)

        expect(config.additional_business_days.count(date)).to eq(1)
      end
    end

    context "with invalid inputs" do
      it "raises InvalidArgumentError for invalid type" do
        expect do
          config.add_business_day(123)
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Invalid date type/)
      end

      it "raises InvalidDateError for invalid string format" do
        expect do
          config.add_business_day("invalid-date")
        end.to raise_error(JapaneseBusinessDays::InvalidDateError, /Invalid date format/)
      end
    end
  end

  describe "#additional_holiday?" do
    it "returns true for dates in additional holidays" do
      date = Date.new(2024, 12, 31)
      config.add_holiday(date)

      expect(config.additional_holiday?(date)).to be true
    end

    it "returns false for dates not in additional holidays" do
      date = Date.new(2024, 12, 31)

      expect(config.additional_holiday?(date)).to be false
    end
  end

  describe "#additional_business_day?" do
    it "returns true for dates in additional business days" do
      date = Date.new(2024, 1, 1)
      config.add_business_day(date)

      expect(config.additional_business_day?(date)).to be true
    end

    it "returns false for dates not in additional business days" do
      date = Date.new(2024, 1, 1)

      expect(config.additional_business_day?(date)).to be false
    end
  end

  describe "#weekend_day?" do
    it "returns true for default weekend days" do
      expect(config.weekend_day?(0)).to be true  # Sunday
      expect(config.weekend_day?(6)).to be true  # Saturday
    end

    it "returns false for default weekdays" do
      (1..5).each do |wday|
        expect(config.weekend_day?(wday)).to be false
      end
    end

    it "returns true for custom weekend days" do
      config.weekend_days = [5, 6] # Friday and Saturday

      expect(config.weekend_day?(5)).to be true  # Friday
      expect(config.weekend_day?(6)).to be true  # Saturday
      expect(config.weekend_day?(0)).to be false # Sunday (no longer weekend)
    end
  end

  describe "#reset!" do
    it "clears all custom settings and restores defaults" do
      # Add some custom settings
      config.add_holiday(Date.new(2024, 12, 31))
      config.add_business_day(Date.new(2024, 1, 1))
      config.weekend_days = [5, 6]

      # Reset
      config.reset!

      # Check defaults are restored
      expect(config.additional_holidays).to be_empty
      expect(config.additional_business_days).to be_empty
      expect(config.weekend_days).to eq([0, 6])
    end
  end
end
