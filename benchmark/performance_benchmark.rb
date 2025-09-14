#!/usr/bin/env ruby
# frozen_string_literal: true

# ベンチマーク実行スクリプト
# 使用方法: ruby benchmark/performance_benchmark.rb

require_relative "../lib/japanese_business_days"
require_relative "../spec/support/benchmark_helper"
require "benchmark"

class PerformanceBenchmark
  def initialize
    @results = {}
  end

  def run_all_benchmarks
    puts "JapaneseBusinessDays Performance Benchmark"
    puts "=========================================="
    puts "Ruby version: #{RUBY_VERSION}"
    puts "Platform: #{RUBY_PLATFORM}"
    puts "Date: #{Time.now}"
    puts

    # 基本操作のベンチマーク
    run_basic_operations_benchmark

    # スケーラビリティテスト
    run_scalability_benchmark

    # メモリ使用量テスト
    run_memory_benchmark

    # キャッシュ効果のテスト
    run_cache_benchmark

    # 実用的なシナリオテスト
    run_real_world_scenarios

    # 結果のサマリー
    print_summary
  end

  private

  def run_basic_operations_benchmark
    puts "1. Basic Operations Benchmark"
    puts "-----------------------------"

    date = Date.new(2024, 1, 10)
    start_date = Date.new(2024, 1, 1)
    end_date = Date.new(2024, 1, 31)

    benchmarks = {
      "business_day?" => -> { JapaneseBusinessDays.business_day?(date) },
      "holiday?" => -> { JapaneseBusinessDays.holiday?(date) },
      "business_days_between" => -> { JapaneseBusinessDays.business_days_between(start_date, end_date) },
      "add_business_days" => -> { JapaneseBusinessDays.add_business_days(date, 10) },
      "subtract_business_days" => -> { JapaneseBusinessDays.subtract_business_days(date, 5) },
      "next_business_day" => -> { JapaneseBusinessDays.next_business_day(date) },
      "previous_business_day" => -> { JapaneseBusinessDays.previous_business_day(date) },
      "holidays_in_year" => -> { JapaneseBusinessDays.holidays_in_year(2024) }
    }

    @results[:basic_operations] = BenchmarkHelper.compare_benchmarks(benchmarks, 10_000)
  end

  def run_scalability_benchmark
    puts "\n2. Scalability Benchmark"
    puts "------------------------"

    # 異なるデータサイズでの性能測定
    [100, 1000, 10_000].each do |size|
      puts "\nTesting with #{size} operations:"

      dates = (1..size).map { |i| Date.new(2024, 1, 1) + i }

      result = BenchmarkHelper.run_benchmark("#{size} business_day? calls", 1) do
        dates.each { |d| JapaneseBusinessDays.business_day?(d) }
      end

      @results["scalability_#{size}"] = result
    end

    # 長期間の営業日計算
    puts "\nLong-term calculations:"

    periods = [
      ["1 month", Date.new(2024, 1, 1), Date.new(2024, 1, 31)],
      ["1 quarter", Date.new(2024, 1, 1), Date.new(2024, 3, 31)],
      ["1 year", Date.new(2024, 1, 1), Date.new(2024, 12, 31)],
      ["5 years", Date.new(2020, 1, 1), Date.new(2024, 12, 31)]
    ]

    periods.each do |name, start_date, end_date|
      result = BenchmarkHelper.run_benchmark("#{name} calculation", 100) do
        JapaneseBusinessDays.business_days_between(start_date, end_date)
      end
      @results["period_#{name.tr(" ", "_")}"] = result
    end
  end

  def run_memory_benchmark
    puts "\n3. Memory Usage Benchmark"
    puts "-------------------------"

    # メモリ使用量の測定
    memory_tests = [
      ["1000 business_day? calls", lambda {
        1000.times { |i| JapaneseBusinessDays.business_day?(Date.new(2024, 1, 1) + i) }
      }],
      ["100 business_days_between calls", lambda {
        100.times do |i|
          start_date = Date.new(2024, 1, 1) + i
          end_date = start_date + 30
          JapaneseBusinessDays.business_days_between(start_date, end_date)
        end
      }],
      ["10 years holiday data", lambda {
        (2020..2029).each { |year| JapaneseBusinessDays.holidays_in_year(year) }
      }]
    ]

    memory_tests.each do |name, test|
      memory_usage = BenchmarkHelper.measure_memory_usage(&test)
      puts "#{name}:"
      puts "  Memory increase: #{memory_usage[:increase].round(2)}MB"
      puts "  Initial: #{memory_usage[:initial].round(2)}MB"
      puts "  Final: #{memory_usage[:final].round(2)}MB"

      @results["memory_#{name.tr(" ", "_").delete("?")}"] = memory_usage
    end
  end

  def run_cache_benchmark
    puts "\n4. Cache Performance Benchmark"
    puts "------------------------------"

    year = 2024

    # 新しい年を使ってキャッシュなし状態を作る
    uncached_year = 2030

    # 初回アクセス（キャッシュなし）
    first_access = BenchmarkHelper.run_benchmark("First access (no cache)", 100) do
      JapaneseBusinessDays.holidays_in_year(uncached_year)
    end

    # 2回目以降のアクセス（キャッシュあり）
    cached_access = BenchmarkHelper.run_benchmark("Cached access", 100) do
      JapaneseBusinessDays.holidays_in_year(year)
    end

    cache_improvement = first_access[:avg_time_ms] / cached_access[:avg_time_ms]
    puts "Cache improvement: #{cache_improvement.round(2)}x faster"

    @results[:cache_first] = first_access
    @results[:cache_cached] = cached_access
    @results[:cache_improvement] = cache_improvement
  end

  def run_real_world_scenarios
    puts "\n5. Real-world Scenarios Benchmark"
    puts "----------------------------------"

    scenarios = {
      "Monthly payroll processing" => lambda {
        # 月次給与処理のシミュレーション
        start_date = Date.new(2024, 1, 1)
        end_date = Date.new(2024, 1, 31)

        # 各日の営業日判定
        (start_date..end_date).each { |date| JapaneseBusinessDays.business_day?(date) }

        # 営業日数計算
        JapaneseBusinessDays.business_days_between(start_date, end_date)

        # 支払期日計算
        5.times do |i|
          base_date = start_date + (i * 6)
          JapaneseBusinessDays.add_business_days(base_date, 30)
        end
      },

      "Project timeline calculation" => lambda {
        # プロジェクトタイムライン計算
        project_start = Date.new(2024, 4, 1)

        # マイルストーン計算
        milestones = [30, 60, 90, 120].map do |days|
          JapaneseBusinessDays.add_business_days(project_start, days)
        end

        # 各マイルストーン間の営業日数
        milestones.each_cons(2) do |start_milestone, end_milestone|
          JapaneseBusinessDays.business_days_between(start_milestone, end_milestone)
        end
      },

      "Financial settlement processing" => lambda {
        # 金融決済処理
        settlement_dates = []

        # 月末決済日計算
        12.times do |month|
          month_end = Date.new(2024, month + 1, -1)
          # 営業日でない場合は前営業日
          settlement_date = if JapaneseBusinessDays.business_day?(month_end)
                              month_end
                            else
                              JapaneseBusinessDays.previous_business_day(month_end)
                            end
          settlement_dates << settlement_date
        end

        # T+3決済日計算
        10.times do |i|
          trade_date = Date.new(2024, 6, 1) + i
          settlement_date = JapaneseBusinessDays.add_business_days(trade_date, 3)
          settlement_dates << settlement_date
        end
      },

      "Delivery scheduling" => lambda {
        # 配送スケジューリング
        order_dates = (1..50).map { |i| Date.new(2024, 1, 1) + i }

        order_dates.each do |order_date|
          # 注文日が営業日でない場合は次営業日に処理
          processing_date = if JapaneseBusinessDays.business_day?(order_date)
                              order_date
                            else
                              JapaneseBusinessDays.next_business_day(order_date)
                            end

          # 3営業日後に配送
          JapaneseBusinessDays.add_business_days(processing_date, 3)
        end
      }
    }

    scenarios.each do |name, scenario|
      result = BenchmarkHelper.run_benchmark(name, 100, &scenario)
      @results["scenario_#{name.tr(" ", "_").downcase}"] = result
    end
  end

  def print_summary
    puts "\n6. Performance Summary"
    puts "======================"

    # 基本操作の性能サマリー
    if @results[:basic_operations]
      puts "\nBasic Operations (operations per second):"
      @results[:basic_operations].each do |operation, result|
        puts "  #{operation}: #{result[:ops_per_sec].round(0)} ops/sec"
      end
    end

    # スケーラビリティサマリー
    puts "\nScalability (operations per second):"
    [100, 1000, 10_000].each do |size|
      result = @results["scalability_#{size}"]
      if result
        ops_per_sec = size / result[:total_time]
        puts "  #{size} operations: #{ops_per_sec.round(0)} ops/sec"
      end
    end

    # メモリ使用量サマリー
    puts "\nMemory Usage:"
    @results.select { |k, _| k.to_s.start_with?("memory_") }.each do |key, result|
      name = key.to_s.gsub("memory_", "").tr("_", " ")
      puts "  #{name}: #{result[:increase].round(2)}MB increase"
    end

    # キャッシュ効果
    if @results[:cache_improvement]
      puts "\nCache Performance:"
      puts "  Cache improvement: #{@results[:cache_improvement].round(2)}x faster"
    end

    # 実用シナリオの性能
    puts "\nReal-world Scenarios (average time):"
    @results.select { |k, _| k.to_s.start_with?("scenario_") }.each do |key, result|
      name = key.to_s.gsub("scenario_", "").tr("_", " ").split.map(&:capitalize).join(" ")
      puts "  #{name}: #{result[:avg_time_ms].round(2)}ms"
    end

    puts "\nBenchmark completed successfully!"
  end
end

# ベンチマーク実行
if __FILE__ == $PROGRAM_NAME
  benchmark = PerformanceBenchmark.new
  benchmark.run_all_benchmarks
end
