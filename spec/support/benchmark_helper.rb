# frozen_string_literal: true

require "benchmark"

module BenchmarkHelper
  # ベンチマーク実行のヘルパーメソッド
  def self.run_benchmark(name, iterations = 1000, &block)
    puts "\n=== #{name} ==="

    # ウォームアップ
    10.times(&block)

    # ベンチマーク実行
    result = Benchmark.measure do
      iterations.times(&block)
    end

    avg_time_ms = (result.real * 1000) / iterations
    ops_per_sec = iterations / result.real

    puts "Total time: #{result.real.round(4)}s"
    puts "Average time per operation: #{avg_time_ms.round(4)}ms"
    puts "Operations per second: #{ops_per_sec.round(0)}"
    puts "Memory usage: #{get_memory_usage_mb.round(2)}MB"

    {
      total_time: result.real,
      avg_time_ms: avg_time_ms,
      ops_per_sec: ops_per_sec,
      memory_mb: get_memory_usage_mb
    }
  end

  # 複数のベンチマークを比較実行
  def self.compare_benchmarks(benchmarks, iterations = 1000)
    results = {}

    benchmarks.each do |name, block|
      results[name] = run_benchmark(name, iterations, &block)
    end

    puts "\n=== Comparison ==="
    fastest = results.min_by { |_, result| result[:avg_time_ms] }

    results.each do |name, result|
      ratio = result[:avg_time_ms] / fastest[1][:avg_time_ms]
      puts "#{name}: #{ratio.round(2)}x slower than fastest" if ratio > 1
      puts "#{name}: fastest" if ratio == 1
    end

    results
  end

  # メモリ使用量測定
  def self.measure_memory_usage
    GC.start
    initial_memory = get_memory_usage_mb

    yield

    GC.start
    final_memory = get_memory_usage_mb

    {
      initial: initial_memory,
      final: final_memory,
      increase: final_memory - initial_memory
    }
  end

  # プロファイリング実行
  def self.profile_execution(name)
    puts "\n=== Profiling: #{name} ==="

    # オブジェクト数の測定
    GC.start
    initial_objects = ObjectSpace.count_objects

    start_time = Time.now
    result = yield
    end_time = Time.now

    GC.start
    final_objects = ObjectSpace.count_objects

    # 結果の表示
    puts "Execution time: #{((end_time - start_time) * 1000).round(4)}ms"
    puts "Objects created:"

    initial_objects.each do |type, initial_count|
      final_count = final_objects[type] || 0
      created = final_count - initial_count
      puts "  #{type}: #{created}" if created > 0
    end

    result
  end

  def self.get_memory_usage_mb
    if RUBY_PLATFORM.include?("linux")
      # Linuxの場合
      status = File.read("/proc/#{Process.pid}/status")
      vmrss_line = status.lines.find { |line| line.start_with?("VmRSS:") }
      if vmrss_line
        vmrss_kb = vmrss_line.split[1].to_i
        return vmrss_kb / 1024.0
      end
    elsif RUBY_PLATFORM.include?("darwin")
      # macOSの場合
      ps_output = `ps -o rss= -p #{Process.pid}`.strip
      rss_kb = ps_output.to_i
      return rss_kb / 1024.0 if rss_kb > 0
    end

    # フォールバック
    ObjectSpace.count_objects[:T_OBJECT] * 0.001
  end
end
