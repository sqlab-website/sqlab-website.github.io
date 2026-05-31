# 結縁・中澤研サイト

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
MEMBERS_SHEET_ID=メンバー用GoogleスプレッドシートID ruby scripts/sync_members_from_sheet.rb
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
RESEARCH_SHEET_ID=研究内容用GoogleスプレッドシートID RESEARCH_SHEET_GID=0 ruby scripts/sync_research_from_sheet.rb
```

`RESEARCH_SHEET_ID`には、`https://docs.google.com/spreadsheets/d/...` のURL全体を入れても動きます。

GitHub Actionsで自動同期する場合は、リポジトリのSecretsに`RESEARCH_SHEET_CSV_URL`または`RESEARCH_SHEET_ID`を設定します。メンバーとは別タブで管理する場合は`RESEARCH_SHEET_GID`にそのタブのgidを設定します。シートは「リンクを知っている全員が閲覧可」にしておきます。

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

現在、公開サイトの業績一覧はBibTeXから生成します。Google Sheetsからの業績同期はGitHub Actionsでは実行しません。

過去のGoogle Sheets形式は次の列でした。

必要な列:

```text
id,only_en,authors_ja,authors_en,title_ja,title_en,publisher_ja,publisher_en,year,doi,order
```

`only_en`が空欄の場合は、日本語ページに日本語欄、英語ページに英語欄を表示します。ただし、`title_ja`が空欄で`title_en`がある場合は、日本語ページにも英語欄を表示します。`only_en`が`1`の場合は、英語欄を日本語ページと英語ページの両方に表示します。`only_en`が`0`の場合は、日本語ページのみに日本語欄を表示します。表示順は`year`の降順、同じ`year`内では`order`の昇順です。`doi`には`10.xxxx/...`形式のDOIまたはURLを入力できます。`doi`がある場合はタイトルにリンクを付けます。

ローカルで手動確認する場合:

```bash
PUBLICATIONS_SHEET_ID=GoogleスプレッドシートID PUBLICATIONS_SHEET_GID=0 ruby scripts/sync_publications_from_sheet.rb
```

公開サイトに反映する業績は、次の「BibTeXから業績を同期」の方法で更新します。

## BibTeXから業績を同期

複数のBibTeXファイルを読み込み、統合した業績一覧を生成できます。

標準の置き場所:

```text
_bibliography/*.bib
```

たとえば次のように、複数のBibTeXファイルを置けます。

```text
_bibliography/
  yuen.bib
  nakazawa.bib
  students.bib
```

GitHub Actionsでは、`_bibliography/*.bib`が1つ以上ある場合、自動的にBibTeX同期を使います。この場合、業績のGoogle Sheets同期よりBibTeX同期が優先されます。

ローカル実行例:

```bash
PUBLICATIONS_BIB_DIR=_bibliography ruby scripts/sync_publications_from_bibtex.rb
```

ファイルを明示する場合:

```bash
PUBLICATIONS_BIB_FILES=_bibliography/yuen.bib,_bibliography/nakazawa.bib ruby scripts/sync_publications_from_bibtex.rb
```

Google Drive上のBibTeXファイルを読む場合:

```bash
PUBLICATIONS_BIB_URLS="https://drive.google.com/file/d/.../view?usp=sharing,https://drive.google.com/file/d/.../view?usp=sharing" ruby scripts/sync_publications_from_bibtex.rb
```

Google Driveのフォルダ内にあるBibTeXファイルをまとめて読む場合:

```bash
PUBLICATIONS_BIB_FOLDER_URL="https://drive.google.com/drive/folders/..." PUBLICATIONS_BIB_API_KEY="Google API key" ruby scripts/sync_publications_from_bibtex.rb
```

共有ドライブの`SQlabWWW/publications`に`.bib`ファイルを置く場合は、`publications`フォルダのURLを`PUBLICATIONS_BIB_FOLDER_URL`に設定します。フォルダURLの代わりにフォルダIDだけを`PUBLICATIONS_BIB_FOLDER_ID`に設定しても構いません。フォルダ内の`.bib`ファイルだけを読み込み、複数ファイルを統合します。

GitHub ActionsでGoogle Drive上のBibTeXを使う場合は、リポジトリのSecretsに次の値を設定します。

- `PUBLICATIONS_BIB_FOLDER_URL`: `SQlabWWW/publications`フォルダのURL
- `PUBLICATIONS_BIB_API_KEY`: Google Drive APIを有効にしたGoogle API key

個別ファイルURLを使う場合は、`PUBLICATIONS_BIB_URLS`に複数ファイルをカンマ区切りで指定します。BibTeXを使う場合、業績のGoogle Sheets同期よりBibTeX同期が優先されます。Drive上の`.bib`ファイル、または`.bib`を置いたフォルダは「リンクを知っている全員が閲覧可」にしておきます。

対応するBibTeX entry:

- `@article`
- `@inproceedings`
- `@techreport`
- `@misc`のうち、フィールド中に「受賞」を含むもの

`@article`では次のフィールドを収集します。

```text
author,title,journal,volume,number,year,doi
```

`@inproceedings`では次のフィールドを収集します。

```text
author,title,booktitle,series,pages,publisher,year,doi
```

`@techreport`では次のフィールドを収集します。

```text
title,author,institution,year,type,number,month,doi
```

受賞として扱う`@misc`では次のフィールドを収集します。日本語の業績ページにのみ表示します。

```text
author,title,howpublished,year,month
```

BibTeX keyを`id`として使います。同じkeyが複数ファイルにある場合は、最初に読まれた1件だけを採用します。表示順は`year`の降順、同じ`year`内では`month`の降順、`month`がない場合は`0`として扱い、その後にBibTeXファイル内での出現順です。`month`は表示しません。`doi`がある場合は、タイトルにDOIリンクを付けます。

## Google Sheetsからニュースを同期

Google SheetsをCSVとして読み込み、日本語ニュースページを生成できます。

必要な列:

```text
date,show_until,slug,title_ja,body_ja,order
```

`date`は`YYYY-MM-DD`形式です。`show_until`に日付がある場合、その日付以降はニュース一覧とホームのお知らせ欄に表示しません。空欄の場合は表示し続けます。`slug`はURLに使われます。空欄の場合はタイトルから自動生成します。同期で生成されたニュースだけを次回同期時に作り直すため、手書きの`_news/*.md`は残ります。

ローカル実行例:

```bash
NEWS_SHEET_ID=GoogleスプレッドシートID NEWS_SHEET_GID=0 ruby scripts/sync_news_from_sheet.rb
```

GitHub Actionsで自動同期する場合は、リポジトリのSecretsに`NEWS_SHEET_CSV_URL`または`NEWS_SHEET_ID`を設定します。シートは「リンクを知っている全員が閲覧可」にしておきます。

## Google Sheetsの編集をきっかけに更新

GitHub Actionsの`schedule`は遅延・未実行になることがあるため、Google Sheetsを編集したタイミングでGitHub Actionsを起動できます。編集後すぐには起動せず、最後の編集から2分後にGitHub Actionsを起動します。

使うファイル:

```text
scripts/google_sheets_workflow_dispatch.gs
```

設定手順:

1. GitHubでPersonal access tokenを作成します。
   - Fine-grained tokenの場合、対象リポジトリを`sqlab-website/sqlab-website.github.io`に限定します。
   - Repository permissionsで`Actions: Read and write`を許可します。
2. Google Sheetsで `拡張機能` -> `Apps Script` を開きます。
3. `scripts/google_sheets_workflow_dispatch.gs` の内容を貼り付けます。
4. Apps Scriptの `プロジェクトの設定` -> `スクリプト プロパティ` に次を追加します。

```text
GITHUB_TOKEN = 作成したPersonal access token
```

5. Apps Scriptの `トリガー` で、次のトリガーを追加します。
   - 実行する関数: `onSheetEdit`
   - イベントのソース: `スプレッドシートから`
   - イベントの種類: `編集時`
6. 必要なら、構造変更にも反応するように次のトリガーも追加します。
   - 実行する関数: `onSheetChange`
   - イベントのソース: `スプレッドシートから`
   - イベントの種類: `変更時`
7. `testWebsiteWorkflowDispatch` を手動実行し、GitHub Actionsが起動することを確認します。

同じ設定を、メンバー・研究内容・イベント・業績・ニュースの各Google Sheetsに入れると、それぞれの編集をきっかけにサイト更新が走ります。短時間に何度も編集した場合は、2分後の起動予約を作り直します。また、`MIN_INTERVAL_MINUTES`により5分以内の連続起動を抑制します。

## GitHub Pagesで公開

1. このフォルダをGitHubリポジトリにpushします。
2. GitHubの `Settings` -> `Pages` を開きます。
3. Sourceを `GitHub Actions` にします。
4. `main` ブランチにpushすると `.github/workflows/pages.yml` がサイトをビルドして公開します。
