# frozen_string_literal: true

module JapaneseBusinessDays
  # 基底エラークラス
  class Error < StandardError; end

  # 無効な日付エラー
  class InvalidDateError < Error; end

  # 無効な引数エラー
  class InvalidArgumentError < Error; end

  # 設定エラー
  class ConfigurationError < Error; end
end