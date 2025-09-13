# frozen_string_literal: true

RSpec.describe JapaneseBusinessDays do
  it "has a version number" do
    expect(JapaneseBusinessDays::VERSION).not_to be nil
  end

  it "loads core interfaces successfully" do
    expect(JapaneseBusinessDays::Configuration).to be_a(Class)
    expect(JapaneseBusinessDays::Holiday).to be_a(Class)
    expect(JapaneseBusinessDays::HolidayCalculator).to be_a(Class)
    expect(JapaneseBusinessDays::BusinessDayCalculator).to be_a(Class)
  end
end
