# frozen_string_literal: true

module JapaneseBusinessDays
  # 基底エラークラス
  class Error < StandardError
    # エラーコンテキスト情報
    attr_reader :context, :suggestions

    # @param message [String] エラーメッセージ
    # @param context [Hash] エラーが発生したコンテキスト情報
    # @param suggestions [Array<String>] 解決方法の提案
    def initialize(message = nil, context: {}, suggestions: [])
      @context = context
      @suggestions = suggestions

      enhanced_message = build_enhanced_message(message)
      super(enhanced_message)
    end

    # エラー情報を構造化された形で取得
    # @return [Hash] エラー情報
    def to_h
      {
        error_class: self.class.name,
        message: message,
        context: context,
        suggestions: suggestions,
        timestamp: Time.now.strftime("%Y-%m-%dT%H:%M:%S%z")
      }
    end

    private

    # 拡張されたエラーメッセージを構築
    # @param base_message [String] 基本メッセージ
    # @return [String] 拡張されたメッセージ
    def build_enhanced_message(base_message)
      parts = []
      parts << base_message if base_message

      if context.any?
        context_info = context.map { |k, v| "#{k}: #{v}" }.join(", ")
        parts << "Context: #{context_info}"
      end

      if suggestions.any?
        suggestion_text = suggestions.map.with_index(1) { |s, i| "#{i}. #{s}" }.join("; ")
        parts << "Suggestions: #{suggestion_text}"
      end

      parts.join(" | ")
    end
  end

  # 無効な日付エラー
  class InvalidDateError < Error
    # @param message [String] エラーメッセージ
    # @param invalid_date [Object] 無効な日付値
    # @param expected_format [String] 期待される形式
    def initialize(message = nil, invalid_date: nil, expected_format: nil, **options)
      context = options[:context] || {}
      context[:invalid_date] = invalid_date if invalid_date
      context[:expected_format] = expected_format if expected_format

      suggestions = options[:suggestions] || []
      suggestions = build_date_suggestions(invalid_date, expected_format) if suggestions.empty?

      super(message, context: context, suggestions: suggestions)
    end

    private

    # 日付エラー用の提案を生成
    def build_date_suggestions(invalid_date, _expected_format)
      suggestions = []

      if invalid_date.is_a?(String)
        suggestions << "Use ISO format (YYYY-MM-DD) like '2024-01-01'"
        suggestions << "Ensure the date string is not empty or blank"
        suggestions << "Check for typos in the date string"
      elsif invalid_date.nil?
        suggestions << "Provide a non-nil date value"
        suggestions << "Use Date.today for current date"
      else
        suggestions << "Use Date, Time, DateTime, or String objects"
        suggestions << "Convert your object to Date using .to_date if available"
      end

      suggestions << "Check the date is within valid range (1000-9999 for years)"
      suggestions
    end
  end

  # 無効な引数エラー
  class InvalidArgumentError < Error
    # @param message [String] エラーメッセージ
    # @param parameter_name [String] パラメータ名
    # @param received_value [Object] 受け取った値
    # @param expected_type [Class, String] 期待される型
    def initialize(message = nil, parameter_name: nil, received_value: nil, expected_type: nil, **options)
      context = options[:context] || {}
      context[:parameter_name] = parameter_name if parameter_name
      context[:received_value] = received_value if received_value
      context[:received_type] = received_value.class if received_value
      context[:expected_type] = expected_type if expected_type

      suggestions = options[:suggestions] || []
      suggestions = build_argument_suggestions(parameter_name, received_value, expected_type) if suggestions.empty?

      super(message, context: context, suggestions: suggestions)
    end

    private

    # 引数エラー用の提案を生成
    def build_argument_suggestions(parameter_name, received_value, expected_type)
      suggestions = []

      case parameter_name
      when "days"
        suggestions << "Use positive or negative integers for business days calculation"
        suggestions << "Example: add_business_days(date, 5) or subtract_business_days(date, 3)"
      when "year"
        suggestions << "Use a 4-digit year between 1000 and 9999"
        suggestions << "Example: holidays_in_year(2024)"
      when "date", "start_date", "end_date"
        suggestions << "Use Date, Time, DateTime, or String objects"
        suggestions << "Example: Date.new(2024, 1, 1) or '2024-01-01'"
      when "weekend_days"
        suggestions << "Use an array of integers (0=Sunday, 1=Monday, ..., 6=Saturday)"
        suggestions << "Example: [0, 6] for Sunday and Saturday"
      end

      if received_value.nil?
        suggestions << "Provide a non-nil value for #{parameter_name}"
      elsif expected_type
        suggestions << "Convert the value to #{expected_type} before passing"
      end

      suggestions
    end
  end

  # 設定エラー
  class ConfigurationError < Error
    # @param message [String] エラーメッセージ
    # @param config_key [String] 設定キー
    # @param config_value [Object] 設定値
    def initialize(message = nil, config_key: nil, config_value: nil, **options)
      context = options[:context] || {}
      context[:config_key] = config_key if config_key
      context[:config_value] = config_value if config_value

      suggestions = options[:suggestions] || []
      suggestions = build_configuration_suggestions(config_key, config_value) if suggestions.empty?

      super(message, context: context, suggestions: suggestions)
    end

    private

    # 設定エラー用の提案を生成
    def build_configuration_suggestions(config_key, _config_value)
      suggestions = []

      case config_key
      when "additional_holidays", "additional_business_days"
        suggestions << "Use an array of Date objects"
        suggestions << "Example: [Date.new(2024, 12, 31), Date.new(2024, 1, 2)]"
      when "weekend_days"
        suggestions << "Use an array of integers from 0 to 6"
        suggestions << "Example: [0, 6] for Sunday and Saturday weekends"
      end

      suggestions << "Check the configuration block syntax"
      suggestions << "Ensure all configuration values are of the correct type"
      suggestions << "Review the documentation for valid configuration options"

      suggestions
    end
  end

  # ログ出力機能
  module Logging
    # ログレベル定数
    LOG_LEVELS = {
      debug: 0,
      info: 1,
      warn: 2,
      error: 3
    }.freeze

    class << self
      # 現在のログレベル
      attr_accessor :level

      # ログ出力先
      attr_accessor :logger

      # ログレベルを設定
      # @param level [Symbol] ログレベル (:debug, :info, :warn, :error)
      def level=(level)
        raise ArgumentError, "Invalid log level: #{level}. Valid levels: #{LOG_LEVELS.keys}" unless LOG_LEVELS.key?(level)

        @level = level
      end

      # デバッグログ出力
      # @param message [String] ログメッセージ
      # @param context [Hash] コンテキスト情報
      def debug(message, context = {})
        log(:debug, message, context)
      end

      # 情報ログ出力
      # @param message [String] ログメッセージ
      # @param context [Hash] コンテキスト情報
      def info(message, context = {})
        log(:info, message, context)
      end

      # 警告ログ出力
      # @param message [String] ログメッセージ
      # @param context [Hash] コンテキスト情報
      def warn(message, context = {})
        log(:warn, message, context)
      end

      # エラーログ出力
      # @param message [String] ログメッセージ
      # @param context [Hash] コンテキスト情報
      def error(message, context = {})
        log(:error, message, context)
      end

      # エラーオブジェクトをログ出力
      # @param error [Exception] エラーオブジェクト
      # @param additional_context [Hash] 追加のコンテキスト情報
      def log_error(error, additional_context = {})
        context = additional_context.dup

        context.merge!(error.context) if error.respond_to?(:context)

        context[:error_class] = error.class.name
        context[:backtrace] = error.backtrace&.first(5) if error.backtrace

        log(:error, error.message, context)
      end

      private

      # ログ出力の実装
      # @param level [Symbol] ログレベル
      # @param message [String] メッセージ
      # @param context [Hash] コンテキスト情報
      def log(level, message, context)
        return unless should_log?(level)

        log_entry = build_log_entry(level, message, context)

        if logger
          logger.send(level, log_entry)
        else
          output_to_stderr(level, log_entry)
        end
      end

      # ログ出力すべきかチェック
      # @param level [Symbol] ログレベル
      # @return [Boolean]
      def should_log?(level)
        current_level = @level || :warn
        LOG_LEVELS[level] >= LOG_LEVELS[current_level]
      end

      # ログエントリを構築
      # @param level [Symbol] ログレベル
      # @param message [String] メッセージ
      # @param context [Hash] コンテキスト情報
      # @return [String] ログエントリ
      def build_log_entry(level, message, context)
        timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        level_str = level.to_s.upcase.ljust(5)

        entry = "[#{timestamp}] #{level_str} JapaneseBusinessDays: #{message}"

        if context.any?
          context_str = context.map { |k, v| "#{k}=#{v.inspect}" }.join(" ")
          entry += " | #{context_str}"
        end

        entry
      end

      # 標準エラー出力への出力
      # @param level [Symbol] ログレベル
      # @param log_entry [String] ログエントリ
      def output_to_stderr(_level, log_entry)
        warn(log_entry)
      end
    end

    # デフォルト設定
    self.level = ENV["JAPANESE_BUSINESS_DAYS_LOG_LEVEL"]&.to_sym || :error
  end
end
