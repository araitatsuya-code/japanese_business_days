# frozen_string_literal: true

require "spec_helper"
require "date"

RSpec.describe JapaneseBusinessDays::Holiday do
  describe "#initialize" do
    let(:valid_date) { Date.new(2024, 1, 1) }
    let(:valid_name) { "元日" }
    let(:valid_type) { :fixed }

    context "with valid parameters" do
      it "creates a holiday successfully" do
        holiday = described_class.new(valid_date, valid_name, valid_type)

        expect(holiday.date).to eq(valid_date)
        expect(holiday.name).to eq(valid_name)
        expect(holiday.type).to eq(valid_type)
      end

      it "accepts all valid types" do
        JapaneseBusinessDays::Holiday::VALID_TYPES.each do |type|
          expect do
            described_class.new(valid_date, valid_name, type)
          end.not_to raise_error
        end
      end
    end

    context "with invalid date" do
      it "raises InvalidArgumentError for non-Date object" do
        expect do
          described_class.new("2024-01-01", valid_name, valid_type)
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Date must be a Date object/)
      end

      it "raises InvalidArgumentError for nil date" do
        expect do
          described_class.new(nil, valid_name, valid_type)
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Date must be a Date object/)
      end
    end

    context "with invalid name" do
      it "raises InvalidArgumentError for non-string name" do
        expect do
          described_class.new(valid_date, 123, valid_type)
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Name must be a non-empty string/)
      end

      it "raises InvalidArgumentError for empty string" do
        expect do
          described_class.new(valid_date, "", valid_type)
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Name must be a non-empty string/)
      end

      it "raises InvalidArgumentError for whitespace-only string" do
        expect do
          described_class.new(valid_date, "   ", valid_type)
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Name must be a non-empty string/)
      end

      it "raises InvalidArgumentError for nil name" do
        expect do
          described_class.new(valid_date, nil, valid_type)
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Name must be a non-empty string/)
      end
    end

    context "with invalid type" do
      it "raises InvalidArgumentError for invalid symbol" do
        expect do
          described_class.new(valid_date, valid_name, :invalid)
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Type must be one of/)
      end

      it "raises InvalidArgumentError for string type" do
        expect do
          described_class.new(valid_date, valid_name, "fixed")
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Type must be one of/)
      end

      it "raises InvalidArgumentError for nil type" do
        expect do
          described_class.new(valid_date, valid_name, nil)
        end.to raise_error(JapaneseBusinessDays::InvalidArgumentError, /Type must be one of/)
      end
    end
  end

  describe "#to_s" do
    it "returns formatted string representation" do
      holiday = described_class.new(Date.new(2024, 1, 1), "元日", :fixed)
      expect(holiday.to_s).to eq("2024-01-01 - 元日 (fixed)")
    end
  end

  describe "#==" do
    let(:holiday1) { described_class.new(Date.new(2024, 1, 1), "元日", :fixed) }
    let(:holiday2) { described_class.new(Date.new(2024, 1, 1), "元日", :fixed) }
    let(:holiday3) { described_class.new(Date.new(2024, 1, 2), "元日", :fixed) }

    it "returns true for identical holidays" do
      expect(holiday1).to eq(holiday2)
    end

    it "returns false for different holidays" do
      expect(holiday1).not_to eq(holiday3)
    end

    it "returns false for non-Holiday objects" do
      expect(holiday1).not_to eq("not a holiday")
    end
  end

  describe "#eql?" do
    let(:holiday1) { described_class.new(Date.new(2024, 1, 1), "元日", :fixed) }
    let(:holiday2) { described_class.new(Date.new(2024, 1, 1), "元日", :fixed) }

    it "returns true for identical holidays" do
      expect(holiday1.eql?(holiday2)).to be true
    end
  end

  describe "#hash" do
    let(:holiday1) { described_class.new(Date.new(2024, 1, 1), "元日", :fixed) }
    let(:holiday2) { described_class.new(Date.new(2024, 1, 1), "元日", :fixed) }

    it "returns same hash for identical holidays" do
      expect(holiday1.hash).to eq(holiday2.hash)
    end
  end
end
