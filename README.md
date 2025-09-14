# JapaneseBusinessDays

[![Gem Version](https://badge.fury.io/rb/japanese_business_days.svg)](https://badge.fury.io/rb/japanese_business_days)
[![Ruby](https://github.com/araitatsuya-code/japanese_business_days/workflows/Ruby/badge.svg)](https://github.com/araitatsuya-code/japanese_business_days/actions)
[![Maintainability](https://api.codeclimate.com/v1/badges/example/maintainability)](https://codeclimate.com/github/araitatsuya-code/japanese_business_days/maintainability)

日本の祝日・土日を考慮した包括的な営業日計算ライブラリです。金融・経理・業務システムでの使用に最適化されており、高いパフォーマンスと柔軟なカスタマイズ機能を提供します。

## 特徴

- 🇯🇵 **日本の祝日完全対応** - 固定祝日、移動祝日、ハッピーマンデー祝日、振替休日をすべてサポート
- ⚡ **高速計算** - 効率的なキャッシュシステムによる高速な営業日計算
- 🔧 **柔軟なカスタマイズ** - 組織固有の祝日・営業日・週末設定に対応
- 🚀 **Rails統合** - Date/Time/DateTimeクラスの自動拡張
- 📝 **型安全** - RBS型定義ファイル付属
- 🧪 **高品質** - 包括的なテストカバレッジ

## インストール

Gemfileに以下を追加してください：

```ruby
gem 'japanese_business_days'
```

そして以下を実行：

```bash
$ bundle install
```

または、直接インストール：

```bash
$ gem install japanese_business_days
```

## 基本的な使用方法

### 営業日数の計算

```ruby
require 'japanese_business_days'

# 2つの日付間の営業日数を計算
start_date = Date.new(2024, 1, 1)
end_date = Date.new(2024, 1, 10)
business_days = JapaneseBusinessDays.business_days_between(start_date, end_date)
# => 6 (1/1は元日、1/6-1/8は土日月のためスキップ)
```

### 営業日判定

```ruby
# 営業日かどうかを判定
JapaneseBusinessDays.business_day?(Date.new(2024, 1, 9))  # 火曜日
# => true

JapaneseBusinessDays.business_day?(Date.new(2024, 1, 1))  # 元日
# => false

JapaneseBusinessDays.business_day?(Date.new(2024, 1, 6))  # 土曜日
# => false
```

### 祝日判定

```ruby
# 祝日かどうかを判定
JapaneseBusinessDays.holiday?(Date.new(2024, 1, 1))   # 元日
# => true

JapaneseBusinessDays.holiday?(Date.new(2024, 1, 8))   # 成人の日
# => true

JapaneseBusinessDays.holiday?(Date.new(2024, 1, 9))   # 平日
# => false
```

### 営業日の加算・減算

```ruby
# 営業日を加算
base_date = Date.new(2024, 1, 5)  # 金曜日
next_business_date = JapaneseBusinessDays.add_business_days(base_date, 3)
# => Date.new(2024, 1, 10) (土日をスキップして水曜日)

# 営業日を減算
prev_business_date = JapaneseBusinessDays.subtract_business_days(base_date, 2)
# => Date.new(2024, 1, 3) (水曜日)

# 次の営業日・前の営業日
JapaneseBusinessDays.next_business_day(Date.new(2024, 1, 5))     # => 2024-01-09
JapaneseBusinessDays.previous_business_day(Date.new(2024, 1, 9)) # => 2024-01-05
```

### 年間祝日の取得

```ruby
# 指定した年の全祝日を取得
holidays = JapaneseBusinessDays.holidays_in_year(2024)
holidays.each do |holiday|
  puts "#{holiday.date}: #{holiday.name} (#{holiday.type})"
end
# => 2024-01-01: 元日 (fixed)
#    2024-01-08: 成人の日 (happy_monday)
#    2024-02-11: 建国記念の日 (fixed)
#    ...
```

## Rails統合

Railsアプリケーションでは、Date/Time/DateTimeクラスが自動的に拡張されます：

```ruby
# Date拡張メソッドの使用
Date.today.business_day?           # 営業日判定
Date.today.holiday?                # 祝日判定
Date.today.add_business_days(5)    # 5営業日後
Date.today.subtract_business_days(3) # 3営業日前
Date.today.next_business_day       # 次の営業日
Date.today.previous_business_day   # 前の営業日

# Time/DateTimeでも同様に使用可能（時刻情報は保持される）
Time.current.add_business_days(1)  # 時刻情報を保持して1営業日後
```

### Railsでの実用例

```ruby
# モデルでの使用
class Invoice < ApplicationRecord
  before_save :set_due_date
  
  private
  
  def set_due_date
    self.due_date = issued_at.to_date.add_business_days(30) if issued_at.present?
  end
end

# バリデーションでの使用
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

# ヘルパーでの使用
module ApplicationHelper
  def next_business_day_from(date)
    date.present? ? date.next_business_day : nil
  end
end
```

## カスタム設定

組織固有のビジネスルールに対応するため、柔軟な設定が可能です：

```ruby
JapaneseBusinessDays.configure do |config|
  # カスタム祝日を追加（年末年始の特別休暇など）
  config.add_holiday(Date.new(2024, 12, 30))
  config.add_holiday(Date.new(2024, 12, 31))
  
  # 特定の祝日を営業日として扱う
  config.add_business_day(Date.new(2024, 1, 1))  # 元日を営業日に
  
  # 週末の定義を変更（土曜日のみを週末とする）
  config.weekend_days = [6]  # 0=日曜日, 6=土曜日
end

# 一括設定も可能
JapaneseBusinessDays.configure do |config|
  config.additional_holidays = [
    Date.new(2024, 12, 30),
    Date.new(2024, 12, 31)
  ]
  config.additional_business_days = [Date.new(2024, 1, 1)]
  config.weekend_days = [0, 6]  # デフォルト: 日曜日と土曜日
end
```

### 設定例

```ruby
# 金融機関の設定例
JapaneseBusinessDays.configure do |config|
  # 大晦日を休業日に
  config.add_holiday(Date.new(2024, 12, 31))
  
  # 土曜日のみを週末に（日曜日は営業日）
  config.weekend_days = [6]
end

# 製造業の設定例
JapaneseBusinessDays.configure do |config|
  # 夏季休暇を追加
  (Date.new(2024, 8, 13)..Date.new(2024, 8, 16)).each do |date|
    config.add_holiday(date)
  end
  
  # 一部の祝日は稼働日
  config.add_business_day(Date.new(2024, 5, 3))  # 憲法記念日
  config.add_business_day(Date.new(2024, 5, 4))  # みどりの日
end
```

## 高度な使用方法

### バッチ処理での効率的な計算

```ruby
# 大量の日付ペアの営業日数を効率的に計算
date_pairs = [
  [Date.new(2024, 1, 1), Date.new(2024, 1, 31)],
  [Date.new(2024, 2, 1), Date.new(2024, 2, 29)],
  # ...
]

results = date_pairs.map do |start_date, end_date|
  {
    period: "#{start_date} - #{end_date}",
    business_days: JapaneseBusinessDays.business_days_between(start_date, end_date)
  }
end
```

### 月末営業日の計算

```ruby
def last_business_day_of_month(year, month)
  last_day = Date.new(year, month, -1)
  current_date = last_day
  
  loop do
    return current_date if JapaneseBusinessDays.business_day?(current_date)
    current_date -= 1
  end
end

# 2024年各月の月末営業日
(1..12).each do |month|
  last_bday = last_business_day_of_month(2024, month)
  puts "#{month}月末営業日: #{last_bday}"
end
```

### 営業日のみの日付範囲生成

```ruby
def business_days_in_range(start_date, end_date)
  (start_date..end_date).select { |date| JapaneseBusinessDays.business_day?(date) }
end

# 2024年1月の営業日一覧
january_business_days = business_days_in_range(
  Date.new(2024, 1, 1),
  Date.new(2024, 1, 31)
)
```

## パフォーマンス

JapaneseBusinessDaysは高いパフォーマンスを実現するため、以下の最適化を行っています：

- **祝日キャッシュ**: 年単位での祝日データキャッシュ
- **効率的なアルゴリズム**: O(1)またはO(log n)の時間計算量
- **メモリ効率**: 最小限のメモリ使用量

### ベンチマーク例

```ruby
require 'benchmark'

# 1000回の営業日計算
time = Benchmark.measure do
  1000.times do |i|
    base = Date.new(2024, 1, 1) + i
    JapaneseBusinessDays.add_business_days(base, 5)
  end
end

puts "1000回の計算時間: #{time.real.round(4)}秒"
# => 1000回の計算時間: 0.0234秒 (約0.02ms/回)
```

## エラーハンドリング

適切なエラーハンドリングにより、問題の早期発見と解決が可能です：

```ruby
begin
  result = JapaneseBusinessDays.business_days_between(start_date, end_date)
rescue JapaneseBusinessDays::InvalidDateError => e
  puts "無効な日付形式: #{e.message}"
rescue JapaneseBusinessDays::InvalidArgumentError => e
  puts "無効な引数: #{e.message}"
rescue JapaneseBusinessDays::ConfigurationError => e
  puts "設定エラー: #{e.message}"
end
```

## 対応している祝日

### 固定祝日
- 元日（1月1日）
- 建国記念の日（2月11日）
- 昭和の日（4月29日）
- 憲法記念日（5月3日）
- みどりの日（5月4日）
- こどもの日（5月5日）
- 山の日（8月11日）
- 文化の日（11月3日）
- 勤労感謝の日（11月23日）
- 天皇誕生日（12月23日）

### 移動祝日
- 春分の日（天文学的計算による）
- 秋分の日（天文学的計算による）

### ハッピーマンデー祝日
- 成人の日（1月第2月曜日）
- 海の日（7月第3月曜日）
- 敬老の日（9月第3月曜日）
- スポーツの日（10月第2月曜日）

### 振替休日
- 祝日が日曜日の場合、翌月曜日が振替休日

## 型定義（RBS）

TypeScriptライクな型チェックが可能です：

```ruby
# steep や sorbet での型チェックに対応
JapaneseBusinessDays.business_days_between(Date.new(2024, 1, 1), Date.new(2024, 1, 10))
# => Integer

JapaneseBusinessDays.business_day?(Date.today)
# => Boolean
```

## 要件

- Ruby 2.7.0 以上
- Rails 6.0 以上（Rails統合を使用する場合）

## ドキュメント

- [APIリファレンス](docs/api_reference.md) - 完全なAPIドキュメント
- [ベストプラクティス](examples/best_practices.md) - 効果的な使用方法とパフォーマンス最適化
- [使用例](examples/usage_examples.rb) - 基本的な使用例とサンプルコード
- [金融業界での使用例](examples/financial_calculations.rb) - 金融機関向けの実用例
- [製造業での使用例](examples/manufacturing_scheduling.rb) - 製造業向けの生産スケジュール管理例

## サンプルコード実行

```bash
# 基本的な使用例
ruby examples/usage_examples.rb

# 金融業界での使用例
ruby examples/financial_calculations.rb

# 製造業での使用例
ruby examples/manufacturing_scheduling.rb
```

## よくある質問

### Q: 祝日データはどのように更新されますか？

A: 祝日データはライブラリに組み込まれており、天文学的計算により自動的に正確な日付が計算されます。法改正による祝日の変更があった場合は、ライブラリのアップデートで対応します。

### Q: 海外の祝日には対応していますか？

A: このライブラリは日本の祝日専用です。海外の祝日が必要な場合は、カスタム設定機能を使用して追加してください。

### Q: パフォーマンスはどの程度ですか？

A: 効率的なキャッシュシステムにより、1000回の営業日計算を約0.02秒で実行できます。大量データ処理にも適しています。

### Q: Rails以外のフレームワークでも使用できますか？

A: はい。Sinatra、Hanami、純粋なRubyアプリケーションなど、どのフレームワークでも使用できます。

## トラブルシューティング

### タイムゾーンの問題

```ruby
# 問題: UTCとJSTの違いによる日付のずれ
utc_time = Time.parse('2024-01-01 15:00:00 UTC')

# 解決: 日本時間に変換してから判定
jst_time = utc_time.in_time_zone('Asia/Tokyo')
JapaneseBusinessDays.business_day?(jst_time.to_date)
```

### メモリ使用量の最適化

```ruby
# 大量データ処理時はバッチ処理を使用
def process_large_dataset(dates)
  dates.each_slice(1000) do |batch|
    batch.each { |date| JapaneseBusinessDays.business_day?(date) }
  end
end
```

## 開発

リポジトリをクローンした後、以下を実行して依存関係をインストールしてください：

```bash
$ bin/setup
```

テストを実行するには：

```bash
$ rake spec
```

インタラクティブなコンソールを起動するには：

```bash
$ bin/console
```

ローカルマシンにgemをインストールするには：

```bash
$ bundle exec rake install
```

## 貢献

バグレポートやプルリクエストは [GitHub](https://github.com/araitatsuya-code/japanese_business_days) で歓迎します。このプロジェクトは、協力的で安全な環境を提供することを目的としており、貢献者は[行動規範](https://github.com/araitatsuya-code/japanese_business_days/blob/main/CODE_OF_CONDUCT.md)に従うことが期待されます。

### 開発ガイドライン

1. **テストの追加** - 新機能には必ずテストを追加してください
2. **ドキュメントの更新** - APIの変更時はドキュメントも更新してください
3. **パフォーマンステスト** - 大きな変更時はベンチマークを実行してください
4. **RBS型定義** - 新しいメソッドには型定義を追加してください

### プルリクエストのプロセス

1. フィーチャーブランチを作成
2. 変更を実装し、テストを追加
3. `rake spec` でテストが通ることを確認
4. `rubocop` でコードスタイルをチェック
5. プルリクエストを作成

## ライセンス

このgemは [MIT License](https://opensource.org/licenses/MIT) の下でオープンソースとして利用可能です。

## 行動規範

JapaneseBusinessDaysプロジェクトのコードベース、イシュートラッカー、チャットルーム、メーリングリストでやり取りするすべての人は、[行動規範](https://github.com/araitatsuya-code/japanese_business_days/blob/main/CODE_OF_CONDUCT.md)に従うことが期待されます。

## 謝辞

このライブラリは以下のプロジェクトからインスピレーションを得ています：

- [business](https://github.com/gocardless/business) - 営業日計算のアルゴリズム設計
- [holiday_japan](https://github.com/holiday-jp/holiday_jp-ruby) - 日本の祝日データ
- [business_time](https://github.com/bokmann/business_time) - 設定システムの設計

## サポート

- 📧 Email: araitatsuya.code@gmail.com
- 💬 GitHub Issues: [Issues](https://github.com/araitatsuya-code/japanese_business_days/issues)
- 📖 Documentation: [Wiki](https://github.com/araitatsuya-code/japanese_business_days/wiki)

---

**JapaneseBusinessDays** - 日本の営業日計算を簡単に、正確に。
