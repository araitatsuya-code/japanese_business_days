# JapaneseBusinessDays ベストプラクティスガイド

このガイドでは、JapaneseBusinessDaysライブラリを効果的に使用するためのベストプラクティス、パフォーマンス最適化のヒント、よくある問題の解決方法を説明します。

## 目次

1. [基本的な使用方法](#基本的な使用方法)
2. [パフォーマンス最適化](#パフォーマンス最適化)
3. [エラーハンドリング](#エラーハンドリング)
4. [Rails統合](#rails統合)
5. [カスタム設定](#カスタム設定)
6. [テスト戦略](#テスト戦略)
7. [よくある問題と解決方法](#よくある問題と解決方法)

## 基本的な使用方法

### 推奨される使用パターン

```ruby
# ✅ 良い例: モジュールメソッドを直接使用
business_days = JapaneseBusinessDays.business_days_between(start_date, end_date)

# ✅ 良い例: Rails環境での拡張メソッド使用
next_business_day = Date.today.next_business_day

# ❌ 避けるべき: 不必要なオブジェクト作成
calculator = JapaneseBusinessDays::BusinessDayCalculator.new(...)  # 内部クラスの直接使用
```

### 日付形式の統一

```ruby
# ✅ 推奨: Dateオブジェクトの使用
date = Date.new(2024, 1, 15)
JapaneseBusinessDays.business_day?(date)

# ✅ 許可: ISO形式の文字列
JapaneseBusinessDays.business_day?('2024-01-15')

# ❌ 避けるべき: 曖昧な日付形式
JapaneseBusinessDays.business_day?('1/15/2024')  # 地域により解釈が異なる
```

## パフォーマンス最適化

### 1. 祝日キャッシュの活用

```ruby
# ✅ 良い例: 同一年の複数計算（キャッシュが効く）
year = 2024
dates_in_2024 = [Date.new(2024, 1, 1), Date.new(2024, 5, 1), Date.new(2024, 12, 31)]
dates_in_2024.each { |date| JapaneseBusinessDays.business_day?(date) }

# ❌ 非効率: 年をまたぐ大量計算
(Date.new(2020, 1, 1)..Date.new(2030, 12, 31)).each do |date|
  JapaneseBusinessDays.business_day?(date)  # 毎年新しいキャッシュが必要
end
```

### 2. バッチ処理での最適化

```ruby
# ✅ 効率的なバッチ処理
def calculate_business_days_batch(date_pairs)
  # 年ごとにグループ化してキャッシュ効率を向上
  results = {}
  
  date_pairs.each do |start_date, end_date|
    key = "#{start_date}_#{end_date}"
    results[key] = JapaneseBusinessDays.business_days_between(start_date, end_date)
  end
  
  results
end

# ❌ 非効率: 設定を頻繁に変更
date_pairs.each do |start_date, end_date|
  JapaneseBusinessDays.configure { |config| config.add_holiday(some_date) }  # 毎回キャッシュクリア
  JapaneseBusinessDays.business_days_between(start_date, end_date)
end
```

### 3. メモリ効率の考慮

```ruby
# ✅ メモリ効率的: 必要な情報のみ保持
business_days_count = JapaneseBusinessDays.business_days_between(start_date, end_date)

# ❌ メモリ非効率: 不要な祝日リスト保持
all_holidays = (2020..2030).map { |year| JapaneseBusinessDays.holidays_in_year(year) }.flatten
```

## エラーハンドリング

### 1. 適切な例外処理

```ruby
# ✅ 推奨: 具体的な例外をキャッチ
begin
  result = JapaneseBusinessDays.business_days_between(start_date, end_date)
rescue JapaneseBusinessDays::InvalidDateError => e
  logger.error "Invalid date format: #{e.message}"
  # 適切なフォールバック処理
rescue JapaneseBusinessDays::InvalidArgumentError => e
  logger.error "Invalid argument: #{e.message}"
  # エラー情報をユーザーに表示
end

# ❌ 避けるべき: 汎用的すぎる例外処理
begin
  result = JapaneseBusinessDays.business_days_between(start_date, end_date)
rescue => e
  # 何のエラーかわからない
end
```

### 2. 入力値の事前検証

```ruby
# ✅ 推奨: 事前検証
def safe_business_days_calculation(start_date, end_date)
  return nil if start_date.nil? || end_date.nil?
  return nil unless start_date.is_a?(Date) && end_date.is_a?(Date)
  
  JapaneseBusinessDays.business_days_between(start_date, end_date)
rescue JapaneseBusinessDays::Error => e
  logger.warn "Business days calculation failed: #{e.message}"
  nil
end
```

## Rails統合

### 1. 初期化設定

```ruby
# config/initializers/japanese_business_days.rb
JapaneseBusinessDays.configure do |config|
  # 組織固有の設定
  config.additional_holidays = [
    Date.new(2024, 12, 30),  # 年末特別休暇
    Date.new(2024, 12, 31)   # 大晦日
  ]
  
  # 土曜日のみを週末に（日曜日は営業日）
  config.weekend_days = [6] if Rails.env.production?
end
```

### 2. モデルでの使用

```ruby
class Invoice < ApplicationRecord
  # ✅ 推奨: コールバックでの営業日計算
  before_save :calculate_due_date
  
  private
  
  def calculate_due_date
    return unless issued_at.present?
    
    self.due_date = issued_at.to_date.add_business_days(30)
  end
end

# ✅ 推奨: バリデーションでの営業日チェック
class Meeting < ApplicationRecord
  validate :meeting_date_must_be_business_day
  
  private
  
  def meeting_date_must_be_business_day
    return unless meeting_date.present?
    
    unless meeting_date.business_day?
      errors.add(:meeting_date, 'は営業日である必要があります')
    end
  end
end
```

### 3. ヘルパーメソッドでの活用

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def format_business_date(date, options = {})
    return '' unless date.present?
    
    formatted_date = date.strftime('%Y年%m月%d日')
    
    if options[:show_business_day_info]
      if date.business_day?
        formatted_date += ' (営業日)'
      elsif date.holiday?
        formatted_date += ' (祝日)'
      else
        formatted_date += ' (週末)'
      end
    end
    
    formatted_date
  end
  
  def next_business_day_from(date)
    date.present? ? date.next_business_day : nil
  end
end
```

## カスタム設定

### 1. 環境別設定

```ruby
# ✅ 推奨: 環境に応じた設定
JapaneseBusinessDays.configure do |config|
  case Rails.env
  when 'development', 'test'
    # テスト用の簡単な設定
    config.weekend_days = [0, 6]
  when 'production'
    # 本番環境の実際の営業日設定
    config.additional_holidays = load_company_holidays
    config.weekend_days = company_weekend_days
  end
end

def load_company_holidays
  # データベースやAPIから会社固有の祝日を読み込み
  CompanyHoliday.current_year.pluck(:date)
end
```

### 2. 動的設定の管理

```ruby
# ✅ 推奨: 設定変更の管理
class BusinessDayConfigManager
  def self.update_configuration
    JapaneseBusinessDays.configure do |config|
      config.additional_holidays = fetch_additional_holidays
      config.additional_business_days = fetch_additional_business_days
    end
  end
  
  private
  
  def self.fetch_additional_holidays
    # 外部システムから最新の祝日情報を取得
    ExternalHolidayAPI.fetch_holidays(Date.current.year)
  end
  
  def self.fetch_additional_business_days
    # 特別営業日の設定を取得
    SpecialBusinessDay.current_year.pluck(:date)
  end
end
```

## テスト戦略

### 1. 単体テストでの使用

```ruby
# spec/models/invoice_spec.rb
RSpec.describe Invoice do
  describe '#calculate_due_date' do
    it '発行日から30営業日後を支払期日とする' do
      # 2024年1月5日（金曜日）に発行
      invoice = create(:invoice, issued_at: Date.new(2024, 1, 5))
      
      # 30営業日後は2024年2月16日（金曜日）
      expect(invoice.due_date).to eq(Date.new(2024, 2, 16))
    end
    
    it '祝日をスキップして計算する' do
      # 年末に発行された請求書
      invoice = create(:invoice, issued_at: Date.new(2023, 12, 28))
      
      # 年末年始をスキップして計算される
      expect(invoice.due_date).to be > Date.new(2024, 1, 3)
    end
  end
end
```

### 2. テスト用の設定

```ruby
# spec/support/japanese_business_days_helper.rb
module JapaneseBusinessDaysHelper
  def with_custom_business_days_config(**options)
    original_config = JapaneseBusinessDays.configuration.dup
    
    JapaneseBusinessDays.configure do |config|
      options.each { |key, value| config.send("#{key}=", value) }
    end
    
    yield
  ensure
    JapaneseBusinessDays.configuration = original_config
  end
end

# テストでの使用
RSpec.describe 'カスタム設定のテスト' do
  include JapaneseBusinessDaysHelper
  
  it '土曜日のみを週末とする設定' do
    with_custom_business_days_config(weekend_days: [6]) do
      # 日曜日が営業日として扱われる
      expect(Date.new(2024, 1, 7).business_day?).to be true  # 日曜日
      expect(Date.new(2024, 1, 6).business_day?).to be false # 土曜日
    end
  end
end
```

## よくある問題と解決方法

### 1. タイムゾーンの問題

```ruby
# ❌ 問題: タイムゾーンを考慮しない
utc_time = Time.parse('2024-01-01 15:00:00 UTC')
JapaneseBusinessDays.business_day?(utc_time)  # 日本時間では翌日かもしれない

# ✅ 解決: 日本時間に変換
jst_time = utc_time.in_time_zone('Asia/Tokyo')
JapaneseBusinessDays.business_day?(jst_time.to_date)
```

### 2. 大量データ処理でのメモリ問題

```ruby
# ❌ 問題: 大量のオブジェクトを一度に処理
large_date_range = (Date.new(2020, 1, 1)..Date.new(2030, 12, 31))
business_days = large_date_range.select { |date| date.business_day? }

# ✅ 解決: バッチ処理
def find_business_days_in_range(start_date, end_date, batch_size: 1000)
  business_days = []
  current_date = start_date
  
  while current_date <= end_date
    batch_end = [current_date + batch_size - 1, end_date].min
    batch_business_days = (current_date..batch_end).select { |date| date.business_day? }
    
    yield batch_business_days if block_given?
    business_days.concat(batch_business_days) unless block_given?
    
    current_date = batch_end + 1
  end
  
  business_days unless block_given?
end
```

### 3. 設定の競合状態

```ruby
# ❌ 問題: マルチスレッド環境での設定変更
Thread.new do
  JapaneseBusinessDays.configure { |config| config.weekend_days = [6] }
  # 他のスレッドの計算に影響する可能性
end

# ✅ 解決: スレッドローカルな設定（将来の機能として検討）
# または、設定変更を最小限に抑える
class BusinessDayService
  def initialize(custom_config = {})
    @custom_config = custom_config
  end
  
  def business_day?(date)
    with_temporary_config do
      JapaneseBusinessDays.business_day?(date)
    end
  end
  
  private
  
  def with_temporary_config
    if @custom_config.any?
      original_config = backup_current_config
      apply_custom_config
      result = yield
      restore_config(original_config)
      result
    else
      yield
    end
  end
end
```

### 4. パフォーマンスの問題

```ruby
# ❌ 問題: 不要な計算の繰り返し
def monthly_business_days_report(year)
  (1..12).map do |month|
    start_date = Date.new(year, month, 1)
    end_date = Date.new(year, month, -1)
    
    # 毎回同じ祝日計算が実行される
    business_days = (start_date..end_date).count { |date| date.business_day? }
    { month: month, business_days: business_days }
  end
end

# ✅ 解決: 事前に祝日を取得してキャッシュ
def monthly_business_days_report(year)
  # 年間祝日を一度だけ取得
  yearly_holidays = JapaneseBusinessDays.holidays_in_year(year).map(&:date).to_set
  
  (1..12).map do |month|
    start_date = Date.new(year, month, 1)
    end_date = Date.new(year, month, -1)
    
    business_days = (start_date..end_date).count do |date|
      !date.saturday? && !date.sunday? && !yearly_holidays.include?(date)
    end
    
    { month: month, business_days: business_days }
  end
end
```

## まとめ

JapaneseBusinessDaysライブラリを効果的に使用するためには：

1. **適切な日付形式を使用する** - DateオブジェクトまたはISO形式文字列
2. **キャッシュを活用する** - 同一年の計算をまとめて実行
3. **具体的な例外処理を行う** - JapaneseBusinessDays::Error系の例外をキャッチ
4. **設定変更を最小限に抑える** - 初期化時に設定し、頻繁な変更は避ける
5. **大量データ処理ではバッチ処理を使用する** - メモリ効率を考慮
6. **テストでは適切なモックを使用する** - 予測可能な結果を保証

これらのベストプラクティスに従うことで、パフォーマンスが良く、保守性の高いコードを書くことができます。