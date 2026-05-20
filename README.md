# 未来知能システム研究室サイト

GitHub Pagesで公開できるJekyll製の研究室サイトです。

## ローカル確認

```bash
bundle install
bundle exec jekyll serve
```

表示先は通常 `http://127.0.0.1:4000` です。

## 編集箇所

- 研究室名や連絡先: `_config.yml`
- 研究テーマ: `_data/research.yml`
- メンバー: `_data/members.yml`
- 業績: `_data/publications.yml`
- 進行中のプロジェクト: `_data/projects.yml`
- イベント: `_data/events.yml`
- お知らせ: `_news/*.md`

## Google Sheetsからメンバーを同期

Google SheetsをCSVとして読み込み、メンバー一覧と個人ページを生成できます。

必要な列:

```text
slug,name_ja,name_en,initial,role_ja,role_en,theme_ja,theme_en,bio_ja,bio_en,website_ja,website_en,web,profile_md_ja_url,profile_md_en_url,email,photo_url,order
```

`website_ja`、`website_en`、共通の`web`、`profile_md_ja_url`、`profile_md_en_url`のいずれかにURLがある場合は、個人ページ本文に該当ページへのリンクを表示します。これらがすべて空の場合は、`theme_*`、`bio_*`、`email`から標準プロフィールを生成します。

ローカル実行例:

```bash
MEMBERS_SHEET_ID=1DlJNWJSXtzL4D2cWJcegh9KBKeyoqwT1JIO7HDKzP20 ruby scripts/sync_members_from_sheet.rb
```

GitHub Actionsで自動同期する場合は、リポジトリのSecretsに`MEMBERS_SHEET_CSV_URL`または`MEMBERS_SHEET_ID`を設定します。シートは「リンクを知っている全員が閲覧可」にしておきます。

## Google Sheetsから研究内容を同期

Google SheetsをCSVとして読み込み、研究内容ページとホームページの研究テーマを生成できます。

必要な列:

```text
id,area_ja,area_en,title_ja,title_en,summary_ja,summary_en,description_ja,description_en,tags_ja,tags_en,order
```

`id`はページ内リンクに使われます。空欄の場合は`title_en`または`title_ja`から自動生成します。`tags_*`はカンマ、読点、改行で区切れます。

ローカル実行例:

```bash
RESEARCH_SHEET_ID=1rxuNIuX-vAccC2Sa2JGes1TQwL8Gkcxzga6rkMxSKbo RESEARCH_SHEET_GID=0 ruby scripts/sync_research_from_sheet.rb
```

`RESEARCH_SHEET_ID`には、`https://docs.google.com/spreadsheets/d/...` のURL全体を入れても動きます。

GitHub Actionsで自動同期する場合は、リポジトリのSecretsに`RESEARCH_SHEET_CSV_URL`または`RESEARCH_SHEET_ID`を設定します。今回の研究内容用シートは`RESEARCH_SHEET_ID=1rxuNIuX-vAccC2Sa2JGes1TQwL8Gkcxzga6rkMxSKbo`です。メンバーとは別タブで管理する場合は`RESEARCH_SHEET_GID`にそのタブのgidを設定します。シートは「リンクを知っている全員が閲覧可」にしておきます。

## Google Sheetsからイベントを同期

Google SheetsをCSVとして読み込み、日本語・英語のイベント一覧を生成できます。

必要な列:

```text
date,type_ja,type_en,title_ja,title_en,time,place_ja,place_en,description_ja,description_en,order
```

ローカル実行例:

```bash
EVENTS_SHEET_ID=GoogleスプレッドシートID EVENTS_SHEET_GID=0 ruby scripts/sync_events_from_sheet.rb
```

GitHub Actionsで自動同期する場合は、リポジトリのSecretsに`EVENTS_SHEET_CSV_URL`または`EVENTS_SHEET_ID`を設定します。シートは「リンクを知っている全員が閲覧可」にしておきます。

## Google Sheetsから業績を同期

Google SheetsをCSVとして読み込み、業績一覧を生成できます。

必要な列:

```text
id,only_en,authors_ja,authors_en,title_ja,title_en,publisher_ja,publisher_en,year,doi,order
```

`only_en`が空欄の場合は、日本語ページに日本語欄、英語ページに英語欄を表示します。`only_en`が`1`の場合は、英語欄を日本語ページと英語ページの両方に表示します。`only_en`が`0`の場合は、日本語ページのみに日本語欄を表示します。表示順は`year`の降順、同じ`year`内では`order`の昇順です。`doi`には`10.xxxx/...`形式のDOIまたはURLを入力できます。`doi`がある場合はタイトルにリンクを付けます。

ローカル実行例:

```bash
PUBLICATIONS_SHEET_ID=GoogleスプレッドシートID PUBLICATIONS_SHEET_GID=0 ruby scripts/sync_publications_from_sheet.rb
```

GitHub Actionsで自動同期する場合は、リポジトリのSecretsに`PUBLICATIONS_SHEET_CSV_URL`または`PUBLICATIONS_SHEET_ID`を設定します。シートは「リンクを知っている全員が閲覧可」にしておきます。

## Google Sheetsからニュースを同期

Google SheetsをCSVとして読み込み、日本語ニュースページを生成できます。

必要な列:

```text
date,slug,title_ja,body_ja,order
```

`date`は`YYYY-MM-DD`形式です。`slug`はURLに使われます。空欄の場合はタイトルから自動生成します。同期で生成されたニュースだけを次回同期時に作り直すため、手書きの`_news/*.md`は残ります。

ローカル実行例:

```bash
NEWS_SHEET_ID=GoogleスプレッドシートID NEWS_SHEET_GID=0 ruby scripts/sync_news_from_sheet.rb
```

GitHub Actionsで自動同期する場合は、リポジトリのSecretsに`NEWS_SHEET_CSV_URL`または`NEWS_SHEET_ID`を設定します。シートは「リンクを知っている全員が閲覧可」にしておきます。

## GitHub Pagesで公開

1. このフォルダをGitHubリポジトリにpushします。
2. GitHubの `Settings` -> `Pages` を開きます。
3. Sourceを `GitHub Actions` にします。
4. `main` ブランチにpushすると `.github/workflows/pages.yml` がサイトをビルドして公開します。
