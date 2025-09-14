# JapaneseBusinessDays API リファレンス

このドキュメントは、JapaneseBusinessDaysライブラリの完全なAPIリファレンスです。

## 目次

1. [メインモジュール](#メインモジュール)
2. [Date拡張メソッド](#date拡張メソッド)
3. [設定クラス](#設定クラス)
4. [祝日クラス](#祝日クラス)
5. [エラークラス](#エラークラス)
6. [型定義](#型定義)

## メインモジュール

### JapaneseBusinessDays

日本の営業日計算のメインモジュールです。

#### クラスメソッド

##### `business_days_between(start_date, end_date) → Integer`

2つの日付間の営業日数を計算します。

**パラメータ:**
- `start_date` (Date, Time, DateTime, String) - 開始日
- `end_date` (Date, Time, DateTime, String) - 終了日

**戻り値:**
- `Integer` - 営業日数（開始日が終了日より後の場合は負の値）

**例外:**
- `InvalidArgumentError` - 引数がnilまたは無効な型の場合
- `InvalidDateError` - 日付形式が無効な場合

**例:**
```ruby
JapaneseBusinessDays.business_days_between(Date.new(2024, 1, 1), Date.new(2024, 1, 10))
# => 6

JapaneseBusinessDays.business_days_between('2024-01-01', '2024-01-10')
# => 6
```

##### `business_day?(date) → Boolean`

指定した日付が営業日かどうかを判定します。

**パラメータ:**
- `date` (Date, Time, DateTime, String) - 判定する日付

**戻り値:**
- `Boolean` - 営業日の場合true、非営業日の場合false

**例外:**
- `InvalidArgumentError` - 引数がnilまたは無効な型の場合
- `InvalidDateError` - 日付形式が無効な場合

**例:**
```ruby
JapaneseBusinessDays.business_day?(Date.new(2024, 1, 9))  # 火曜日
# => true

JapaneseBusinessDays.business_day?(Date.new(2024, 1, 1))  # 元日
# => false
```

##### `holiday?(date) → Boolean`

指定した日付が日本の祝日かどうかを判定します。

**パラメータ:**
- `date` (Date, Time, DateTime, String) - 判定する日付

**戻り値:**
- `Boolean` - 祝日の場合true、祝日でない場合false

**例外:**
- `InvalidArgumentError` - 引数がnilまたは無効な型の場合
- `InvalidDateError` - 日付形式が無効な場合

**例:**
```ruby
JapaneseBusinessDays.holiday?(Date.new(2024, 1, 1))  # 元日
# => true

JapaneseBusinessDays.holiday?(Date.new(2024, 1, 8))  # 成人の日
# => true
```

##### `holidays_in_year(year) → Array<Holiday>`

指定した年の全祝日を取得します。

**パラメータ:**
- `year` (Integer) - 対象年（1000-9999の範囲）

**戻り値:**
- `Array<Holiday>` - その年の祝日リスト（日付順）

**例外:**
- `InvalidArgumentError` - 引数がnilまたは無効な型・範囲の場合

**例:**
```ruby
holidays = JapaneseBusinessDays.holidays_in_year(2024)
holidays.each { |h| puts "#{h.date}: #{h.name} (#{h.type})" }
```

##### `add_business_days(date, days) → Date`

指定した日付に営業日を加算します。

**パラメータ:**
- `date` (Date, Time, DateTime, String) - 基準日
- `days` (Integer) - 加算する営業日数（負の値の場合は減算）

**戻り値:**
- `Date` - 計算結果の日付

**例外:**
- `InvalidArgumentError` - 引数がnilまたは無効な型の場合
- `InvalidDateError` - 日付形式が無効な場合

**例:**
```ruby
JapaneseBusinessDays.add_business_days(Date.new(2024, 1, 5), 3)
# => Date.new(2024, 1, 10)

JapaneseBusinessDays.add_business_days(Date.new(2024, 1, 5), -2)
# => Date.new(2024, 1, 3)
```

##### `subtract_business_days(date, days) → Date`

指定した日付から営業日を減算します。

**パラメータ:**
- `date` (Date, Time, DateTime, String) - 基準日
- `days` (Integer) - 減算する営業日数（負の値の場合は加算）

**戻り値:**
- `Date` - 計算結果の日付

**例外:**
- `InvalidArgumentError` - 引数がnilまたは無効な型の場合
- `InvalidDateError` - 日付形式が無効な場合

**例:**
```ruby
JapaneseBusinessDays.subtract_business_days(Date.new(2024, 1, 10), 3)
# => Date.new(2024, 1, 5)
```

##### `next_business_day(date) → Date`

指定した日付の次の営業日を取得します。

**パラメータ:**
- `date` (Date, Time, DateTime, String) - 基準日

**戻り値:**
- `Date` - 次の営業日

**例外:**
- `InvalidArgumentError` - 引数がnilまたは無効な型の場合
- `InvalidDateError` - 日付形式が無効な場合

**例:**
```ruby
JapaneseBusinessDays.next_business_day(Date.new(2024, 1, 5))  # 金曜日
# => Date.new(2024, 1, 9)  # 月曜日
```

##### `previous_business_day(date) → Date`

指定した日付の前の営業日を取得します。

**パラメータ:**
- `date` (Date, Time, DateTime, String) - 基準日

**戻り値:**
- `Date` - 前の営業日

**例外:**
- `InvalidArgumentError` - 引数がnilまたは無効な型の場合
- `InvalidDateError` - 日付形式が無効な場合

**例:**
```ruby
JapaneseBusinessDays.previous_business_day(Date.new(2024, 1, 9))  # 月曜日
# => Date.new(2024, 1, 5)  # 金曜日
```

##### `configure {|config| ... } → void`

ライブラリの設定を行います。

**パラメータ:**
- ブロック - 設定を変更するためのブロック

**例外:**
- `InvalidArgumentError` - ブロックが提供されない場合
- `ConfigurationError` - 設定処理中にエラーが発生した場合

**例:**
```ruby
JapaneseBusinessDays.configure do |config|
  config.add_holiday(Date.new(2024, 12, 31))
  config.weekend_days = [6]  # 土曜日のみを週末に
end
```

##### `configuration → Configuration`

現在の設定オブジェクトを取得します。

**戻り値:**
- `Configuration` - 現在の設定オブジェクト

**例:**
```ruby
config = JapaneseBusinessDays.configuration
puts config.weekend_days  # => [0, 6]
```

## Date拡張メソッド

Rails環境では、Date、Time、DateTime、ActiveSupport::TimeWithZoneクラスに以下のメソッドが自動的に追加されます。

### インスタンスメソッド

##### `add_business_days(days) → Date|Time|DateTime`

営業日を加算します。元のオブジェクトと同じ型で結果を返します。

**パラメータ:**
- `days` (Integer) - 加算する営業日数

**戻り値:**
- 元のオブジェクトと同じ型 - 計算結果

**例:**
```ruby
Date.new(2024, 1, 5).add_business_days(3)
# => Date.new(2024, 1, 10)

Time.new(2024, 1, 5, 14, 30).add_business_days(1)
# => Time.new(2024, 1, 9, 14, 30)  # 時刻情報が保持される
```

##### `subtract_business_days(days) → Date|Time|DateTime`

営業日を減算します。元のオブジェクトと同じ型で結果を返します。

**パラメータ:**
- `days` (Integer) - 減算する営業日数

**戻り値:**
- 元のオブジェクトと同じ型 - 計算結果

**例:**
```ruby
Date.new(2024, 1, 10).subtract_business_days(3)
# => Date.new(2024, 1, 5)
```

##### `business_day? → Boolean`

営業日かどうかを判定します。

**戻り値:**
- `Boolean` - 営業日の場合true

**例:**
```ruby
Date.new(2024, 1, 9).business_day?  # 火曜日
# => true

Date.new(2024, 1, 1).business_day?  # 元日
# => false
```

##### `holiday? → Boolean`

祝日かどうかを判定します。

**戻り値:**
- `Boolean` - 祝日の場合true

**例:**
```ruby
Date.new(2024, 1, 1).holiday?  # 元日
# => true

Date.new(2024, 1, 9).holiday?  # 平日
# => false
```

##### `next_business_day → Date|Time|DateTime`

次の営業日を取得します。元のオブジェクトと同じ型で結果を返します。

**戻り値:**
- 元のオブジェクトと同じ型 - 次の営業日

**例:**
```ruby
Date.new(2024, 1, 5).next_business_day  # 金曜日
# => Date.new(2024, 1, 9)  # 月曜日
```

##### `previous_business_day → Date|Time|DateTime`

前の営業日を取得します。元のオブジェクトと同じ型で結果を返します。

**戻り値:**
- 元のオブジェクトと同じ型 - 前の営業日

**例:**
```ruby
Date.new(2024, 1, 9).previous_business_day  # 月曜日
# => Date.new(2024, 1, 5)  # 金曜日
```

## 設定クラス

### Configuration

カスタムビジネスルールの設定を管理するクラスです。

#### 属性

##### `additional_holidays → Array<Date>`

追加祝日のリストを取得します。

##### `additional_business_days → Array<Date>`

追加営業日のリストを取得します。

##### `weekend_days → Array<Integer>`

週末曜日のリストを取得します（0=日曜日, 6=土曜日）。

#### インスタンスメソッド

##### `additional_holidays=(holidays)`

追加祝日を一括設定します。

**パラメータ:**
- `holidays` (Array<Date>) - 追加する祝日の配列

**例外:**
- `InvalidArgumentError` - 無効な配列または日付オブジェクトの場合

##### `additional_business_days=(business_days)`

追加営業日を一括設定します。

**パラメータ:**
- `business_days` (Array<Date>) - 追加する営業日の配列

**例外:**
- `InvalidArgumentError` - 無効な配列または日付オブジェクトの場合

##### `weekend_days=(days)`

週末曜日を設定します。

**パラメータ:**
- `days` (Array<Integer>) - 週末とする曜日の配列（0-6の整数）

**例外:**
- `InvalidArgumentError` - 無効な配列、重複、または範囲外の値の場合

##### `add_holiday(date)`

カスタム祝日を追加します。

**パラメータ:**
- `date` (Date, Time, DateTime, String) - 追加する祝日

**例外:**
- `InvalidArgumentError` - 引数がnilまたは無効な型の場合
- `InvalidDateError` - 日付形式が無効な場合

##### `add_business_day(date)`

カスタム営業日を追加します。

**パラメータ:**
- `date` (Date, Time, DateTime, String) - 追加する営業日

**例外:**
- `InvalidArgumentError` - 引数がnilまたは無効な型の場合
- `InvalidDateError` - 日付形式が無効な場合

##### `additional_holiday?(date) → Boolean`

指定した日付がカスタム祝日かどうかを判定します。

**パラメータ:**
- `date` (Date) - 判定する日付

**戻り値:**
- `Boolean` - カスタム祝日の場合true

##### `additional_business_day?(date) → Boolean`

指定した日付がカスタム営業日かどうかを判定します。

**パラメータ:**
- `date` (Date) - 判定する日付

**戻り値:**
- `Boolean` - カスタム営業日の場合true

##### `weekend_day?(wday) → Boolean`

指定した曜日が週末かどうかを判定します。

**パラメータ:**
- `wday` (Integer) - 曜日（0=日曜日, 1=月曜日, ..., 6=土曜日）

**戻り値:**
- `Boolean` - 週末の場合true

##### `reset!`

設定をデフォルト値にリセットします。

## 祝日クラス

### Holiday

日本の祝日情報を表すクラスです。

#### 属性

##### `date → Date`

祝日の日付を取得します。

##### `name → String`

祝日名を取得します。

##### `type → Symbol`

祝日の種類を取得します（:fixed, :calculated, :happy_monday, :substitute）。

#### クラス定数

##### `VALID_TYPES`

有効な祝日タイプの配列です。

```ruby
[:fixed, :calculated, :happy_monday, :substitute]
```

#### インスタンスメソッド

##### `initialize(date, name, type)`

祝日オブジェクトを初期化します。

**パラメータ:**
- `date` (Date) - 祝日の日付
- `name` (String) - 祝日名
- `type` (Symbol) - 祝日の種類

**例外:**
- `InvalidArgumentError` - 無効な引数の場合

##### `to_s → String`

祝日の文字列表現を返します。

**戻り値:**
- `String` - "日付 - 祝日名 (種類)" の形式

##### `==(other) → Boolean`

他の祝日オブジェクトと等価かどうかを判定します。

**パラメータ:**
- `other` (Holiday) - 比較対象

**戻り値:**
- `Boolean` - 同じ祝日の場合true

##### `hash → Integer`

ハッシュ値を計算します。

**戻り値:**
- `Integer` - ハッシュ値

## エラークラス

### Error

基底エラークラスです。

#### 属性

##### `context → Hash`

エラーが発生したコンテキスト情報を取得します。

##### `suggestions → Array<String>`

解決方法の提案を取得します。

#### インスタンスメソッド

##### `initialize(message = nil, context: {}, suggestions: [])`

エラーオブジェクトを初期化します。

**パラメータ:**
- `message` (String) - エラーメッセージ
- `context` (Hash) - コンテキスト情報
- `suggestions` (Array<String>) - 解決方法の提案

##### `to_h → Hash`

エラー情報を構造化された形で取得します。

**戻り値:**
- `Hash` - エラー情報

### InvalidDateError < Error

無効な日付エラーです。

### InvalidArgumentError < Error

無効な引数エラーです。

### ConfigurationError < Error

設定エラーです。

## 型定義

### RBS型定義

```rbs
module JapaneseBusinessDays
  VERSION: String
  
  type date_like = Date | Time | DateTime | String
  type holiday_type = :fixed | :calculated | :happy_monday | :substitute
  
  def self.business_days_between: (date_like start_date, date_like end_date) -> Integer
  def self.business_day?: (date_like date) -> bool
  def self.holiday?: (date_like date) -> bool
  def self.holidays_in_year: (Integer year) -> Array[Holiday]
  def self.add_business_days: (date_like date, Integer days) -> Date
  def self.subtract_business_days: (date_like date, Integer days) -> Date
  def self.next_business_day: (date_like date) -> Date
  def self.previous_business_day: (date_like date) -> Date
  def self.configure: () { (Configuration) -> void } -> void
  def self.configuration: () -> Configuration
end
```

### 定数

#### `FIXED_HOLIDAYS`

固定祝日の定義です。

```ruby
{
  [1, 1]   => "元日",
  [2, 11]  => "建国記念の日",
  [4, 29]  => "昭和の日",
  [5, 3]   => "憲法記念日",
  [5, 4]   => "みどりの日",
  [5, 5]   => "こどもの日",
  [8, 11]  => "山の日",
  [11, 3]  => "文化の日",
  [11, 23] => "勤労感謝の日",
  [12, 23] => "天皇誕生日"
}
```

#### `HAPPY_MONDAY_HOLIDAYS`

ハッピーマンデー祝日の定義です。

```ruby
{
  [1, 2] => "成人の日",      # 1月第2月曜日
  [7, 3] => "海の日",       # 7月第3月曜日
  [9, 3] => "敬老の日",     # 9月第3月曜日
  [10, 2] => "スポーツの日"  # 10月第2月曜日
}
```

#### `DEFAULT_WEEKEND_DAYS`

デフォルトの週末曜日です。

```ruby
[0, 6]  # 日曜日と土曜日
```