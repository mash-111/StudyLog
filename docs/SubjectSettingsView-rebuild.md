# SubjectSettingsView 作り直し — 要件定義 & 実装プロンプト

## 1. 要件定義

### 1.1 概要

StudyLog アプリの「カテゴリ設定画面」を一から作り直す。
ContentView から `.sheet` で表示されるモーダル画面で、勉強カテゴリ（Subject）の CRUD と並び替えを行う。

### 1.2 現状の課題

| # | 課題 | 詳細 |
|---|------|------|
| 1 | 状態管理が複雑 | `editMode`, `editingID`, `editingText`, `focusedID` の4つの状態が絡み合い保守しづらい |
| 2 | 編集UXが分かりにくい | EditButton を押さないと編集できない。インライン編集は発見しにくい |
| 3 | エラーフィードバックがない | 重複名の入力時にサイレントに失敗する |
| 4 | 閉じるボタンがない | sheet 表示なのに明示的な閉じる手段がない（スワイプダウンのみ） |
| 5 | commitEdit が internal アクセス | private であるべき関数が internal になっている |

### 1.3 機能要件

#### 一覧表示
- カテゴリ名をリスト表示する
- カテゴリが0件の場合、Section 内に `Text("カテゴリーがありません")` を `.foregroundStyle(.secondary)` で表示する

#### 追加（通常画面のみ）
- リスト内の別セクションに「新しい項目を追加」テキストフィールド + 追加ボタンを表示
- EditMode 中は追加欄を非表示にする
- 空文字・空白のみの入力は追加不可（ボタン disabled）
- 重複名の場合はアラートでユーザーに通知する
- 追加後にテキストフィールドをクリアする

#### 編集（通常画面のみ）
- 通常画面でカテゴリ行をタップすると **Alert（TextFieldつき）** を表示して名前を編集する
- EditMode 中は行タップに反応しない（並び替え・削除に専念）
- Alert には「キャンセル」と「保存」ボタンを配置
- 空文字・空白のみの場合は保存不可
- 重複名の場合はアラートでユーザーに通知する

#### 削除
- 通常画面: スワイプで削除（`.onDelete`）
- EditMode: 削除ボタン（赤丸）で削除

#### 並び替え（EditMode のみ）
- EditMode 中にドラッグで並び替え可能（`.onMove`）
- ツールバーに EditButton を配置

#### ナビゲーション
- ツールバー左側に「閉じる」ボタン（xmark）を配置
- `@Environment(\.dismiss)` で閉じる
- ナビゲーションタイトル: 「カテゴリー設定」

### 1.4 モード別の操作一覧

#### 通常画面（EditMode = inactive）

| 操作 | 可否 | 方法 |
|------|:----:|------|
| 一覧を見る | ○ | リスト表示 |
| 新規追加 | ○ | 下部 TextField + ボタン |
| 名前を編集 | ○ | 行タップ → Alert |
| スワイプ削除 | ○ | 左スワイプ |
| 並び替え | × | — |
| 削除ボタン（赤丸） | × | — |

#### Edit画面（EditMode = active）

| 操作 | 可否 | 方法 |
|------|:----:|------|
| 一覧を見る | ○ | リスト表示 |
| 新規追加 | × | 追加欄は非表示 |
| 名前を編集 | × | タップしても反応しない |
| スワイプ削除 | × | EditMode中は無効 |
| 並び替え | ○ | ドラッグハンドル |
| 削除ボタン（赤丸） | ○ | 各行の左に表示 |

### 1.5 非機能要件

- **状態管理のシンプルさ**: EditMode に依存したインライン編集を廃止し、状態変数を最小限にする
- **アクセシビリティ**: VoiceOver で操作可能であること
- **既存インターフェース維持**: `SubjectStore` の API（add / delete / move / update）はそのまま使う
- **呼び出し元への影響なし**: ContentView の呼び出しコード変更不要

### 1.6 UI構成（概略）

```
NavigationStack
├─ toolbar leading: 閉じるボタン (xmark)
├─ toolbar trailing: EditButton
├─ navigationTitle: "カテゴリー設定"
│
├─ List
│  ├─ Section: カテゴリ一覧
│  │  ├─ ForEach(subjects) → Text(subject.name)
│  │  │   .onTapGesture → 編集アラート表示（通常画面のみ）
│  │  │   .onDelete → 削除
│  │  │   .onMove → 並び替え
│  │  │
│  │  └─ (0件時) → Text("カテゴリーがありません").foregroundStyle(.secondary)
│  │
│  └─ Section: 追加欄（通常画面のみ、EditMode中は非表示）
│     └─ HStack
│        ├─ TextField("新しい項目を追加")
│        └─ Button(plus.circle.fill) → 追加処理
│
└─ .alert(item: $activeAlert) — 1つの alert modifier で全種類を出し分け
   ├─ case .edit(UUID) → TextField付き編集アラート
   ├─ case .duplicateOnAdd → "同じ名前のカテゴリーが既にあります"
   └─ case .duplicateOnEdit → "同じ名前のカテゴリーが既にあります"
```

### 1.7 状態変数（設計）

```swift
@ObservedObject var subjectStore: SubjectStore
@Environment(\.dismiss) private var dismiss

// 追加用
@State private var newSubjectName = ""

// アラート管理（enum で統一、alert の競合を防止）
@State private var activeAlert: AlertType? = nil
@State private var editAlertText = ""

enum AlertType: Identifiable {
    case edit(UUID)        // 編集アラート（対象IDを保持）
    case duplicateOnAdd    // 追加時の重複エラー
    case duplicateOnEdit   // 編集時の重複エラー

    var id: String {
        switch self {
        case .edit(let uuid): return "edit-\(uuid.uuidString)"
        case .duplicateOnAdd: return "dup-add"
        case .duplicateOnEdit: return "dup-edit"
        }
    }
}
```

→ 現状の6つ（editMode含む）から **3つ + dismiss + enum** に整理。
- Alert の状態を `enum AlertType` で統一し、`.alert(item:)` 1つで管理。SwiftUI の alert 競合問題を回避。
- `editTargetID` は `AlertType.edit(UUID)` に統合し、独立した状態変数を削減。
- 追加時と編集時の重複エラーを区別可能（将来のメッセージ出し分けに対応）。
- EditMode は `.environment` で明示管理せず、List のデフォルト挙動に任せる。

---

## 2. 実装プロンプト

以下のプロンプトを Claude に渡して実装を依頼する想定。

---

### プロンプト

```
SubjectSettingView.swift を以下の要件で一から書き直してください。
ファイルパス: StudyLog/SubjectSettingView.swift

## 前提
- SwiftUI (iOS 17+)
- struct名は `SubjectSettingsView` のまま
- @ObservedObject var subjectStore: SubjectStore を受け取る
- SubjectStore の既存API（add, delete, move, update）をそのまま使う
- ContentView からの呼び出しコード（.sheet + SubjectSettingsView(subjectStore:)）は変更不要

## 画面構成
NavigationStack でラップし、以下のツールバーを配置:
- leading: 閉じるボタン（xmark アイコン、@Environment(\.dismiss) で閉じる）
- trailing: EditButton（並び替え・削除用）
- navigationTitle: "カテゴリー設定"

## カテゴリ一覧（List）
- ForEach で subjectStore.subjects を表示（各行は Text(subject.name)）
- .onDelete で削除
- .onMove で並び替え
- 通常画面（EditMode inactive）では行タップで編集アラートを表示（後述）
- EditMode 中は行タップに反応しないこと
- カテゴリが0件の場合、Section 内に Text("カテゴリーがありません") を .foregroundStyle(.secondary) で表示（ContentUnavailableView は使わない）

## 新規追加
- リスト内の別セクションに HStack で配置:
  - TextField("新しい項目を追加", text: $newSubjectName)
  - Button（plus.circle.fill アイコン）で追加実行
- EditMode 中はこのセクションを非表示にする
- 空白のみ・空文字の場合はボタンを disabled にする
- 追加時に重複チェックし、重複なら .duplicateOnAdd アラートを表示
- 成功したら newSubjectName をクリアする

## 編集（Alert）
- 通常画面で行タップ時に .alert（TextField付き）を表示する
- alert の TextField には既存の名前をプリセットする
- 「キャンセル」と「保存」の2ボタン
- 保存時: 空白チェック → guard let で editTargetID を取得 → 重複チェック → subjectStore.update()
- 重複の場合は .duplicateOnEdit アラートを表示

## Alert 管理（重要）
SwiftUI では同一 View に複数の .alert を付けると競合するため、enum で統一管理すること:

```swift
enum AlertType: Identifiable {
    case edit(UUID)
    case duplicateOnAdd
    case duplicateOnEdit

    var id: String {
        switch self {
        case .edit(let uuid): return "edit-\(uuid.uuidString)"
        case .duplicateOnAdd: return "dup-add"
        case .duplicateOnEdit: return "dup-edit"
        }
    }
}
```

- @State private var activeAlert: AlertType? = nil を使い、.alert(item: $activeAlert) で出し分ける
- 編集対象の UUID は AlertType.edit(UUID) から取得する（editTargetID の独立変数は不要）
- editAlertText は編集 Alert の TextField 用に @State で保持する

## 状態変数
以下の最小限の状態変数で実装すること:
- @State private var newSubjectName = ""
- @State private var activeAlert: AlertType? = nil
- @State private var editAlertText = ""

## コード品質
- すべての関数は private にする
- trimmingCharacters(in: .whitespacesAndNewlines) で入力値を正規化
- 不要な EditMode の明示的管理（@State private var editMode）は使わない
- 保存処理で guard let を使い、editTargetID（AlertType.edit から抽出）の nil チェックを行う
```

---

## 3. 確認事項（レビュー時のチェックリスト）

- [ ] 閉じるボタンが機能するか
- [ ] 新規追加 → 一覧に反映されるか
- [ ] 重複名で追加 → アラートが出るか
- [ ] 行タップ → 編集アラートが表示されるか
- [ ] 編集アラートに既存名がプリセットされるか
- [ ] 編集で重複名 → エラーアラートが出るか
- [ ] 空文字で保存 → 保存されないか
- [ ] スワイプ削除が動作するか
- [ ] EditButton → 並び替えハンドルが表示されるか
- [ ] ドラッグ並び替えが動作するか
- [ ] 0件時に空状態メッセージが表示されるか（Text + .secondary）
- [ ] EditMode 中に追加欄が非表示になるか
- [ ] EditMode 中に行タップしても編集アラートが出ないか
- [ ] alert が競合せず正しく出し分けされるか
- [ ] ContentView の呼び出しコードに変更が不要か
