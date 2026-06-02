#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "cgi"
require "json"
require "open-uri"
require "uri"
require "yaml"
require_relative "google_sheets_csv"

BIB_DIR = ENV["PUBLICATIONS_BIB_DIR"].to_s.empty? ? "_bibliography" : ENV["PUBLICATIONS_BIB_DIR"]
BIB_FILES = ENV["PUBLICATIONS_BIB_FILES"].to_s
BibUrl = Struct.new(:url, :label)
BIB_URLS = ENV["PUBLICATIONS_BIB_URLS"].to_s
BIB_FOLDER_ID = ENV["PUBLICATIONS_BIB_FOLDER_ID"].to_s
BIB_FOLDER_URL = ENV["PUBLICATIONS_BIB_FOLDER_URL"].to_s
BIB_API_KEY = ENV["PUBLICATIONS_BIB_API_KEY"].to_s

def abort_with(message)
  warn(message)
  exit(1)
end

def present?(value)
  !value.nil? && !value.to_s.strip.empty?
end

def bib_files
  files = if present?(BIB_FILES)
            BIB_FILES.split(",").map(&:strip)
          else
            Dir.glob(File.join(BIB_DIR, "*.bib")).sort
          end
  files.select { |path| File.file?(path) }
end

def google_drive_folder_id(value)
  return nil unless present?(value)

  text = value.strip
  return Regexp.last_match(1) if text =~ %r{drive\.google\.com/drive/(?:u/\d+/)?folders/([^/?#]+)}
  return Regexp.last_match(1) if text =~ /[?&]id=([^&]+)/

  text
end

def google_drive_folder_bib_urls
  folder_id = google_drive_folder_id(BIB_FOLDER_ID)
  folder_id ||= google_drive_folder_id(BIB_FOLDER_URL)
  return [] unless present?(folder_id)

  token = GoogleSheetsCsv.access_token if GoogleSheetsCsv.service_account_credentials
  abort_with("PUBLICATIONS_BIB_API_KEY or GOOGLE_SERVICE_ACCOUNT_JSON is required when using PUBLICATIONS_BIB_FOLDER_ID or PUBLICATIONS_BIB_FOLDER_URL.") unless present?(BIB_API_KEY) || present?(token)

  urls = []
  page_token = nil

  loop do
    params = {
      "key" => BIB_API_KEY,
      "q" => "'#{folder_id}' in parents and trashed = false",
      "fields" => "nextPageToken,files(id,name,mimeType)",
      "pageSize" => "1000",
      "includeItemsFromAllDrives" => "true",
      "supportsAllDrives" => "true",
      "corpora" => "allDrives"
    }
    params.delete("key") unless present?(BIB_API_KEY)
    params["pageToken"] = page_token if present?(page_token)

    uri = URI("https://www.googleapis.com/drive/v3/files?#{URI.encode_www_form(params)}")
    response = if present?(token)
                 google_drive_get_json(uri, token)
               else
                 JSON.parse(URI.open(uri, &:read))
               end

    response.fetch("files", []).each do |file|
      next unless file["name"].to_s.downcase.end_with?(".bib")

      urls << BibUrl.new("https://drive.google.com/uc?export=download&id=#{file["id"]}", file["name"])
    end

    page_token = response["nextPageToken"]
    break unless present?(page_token)
  end

  urls.sort_by { |source| source.label.to_s }
end

def google_drive_get_json(uri, token)
  request = Net::HTTP::Get.new(uri)
  request["Authorization"] = "Bearer #{token}"
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
  abort_with("Google Drive API request failed: #{response.code} #{response.body}") unless response.is_a?(Net::HTTPSuccess)

  JSON.parse(response.body)
end

def bib_sources
  urls = BIB_URLS.split(",").map(&:strip).select { |url| present?(url) }.map { |url| BibUrl.new(url, url) }
  google_drive_folder_bib_urls + urls + bib_files
end

def google_drive_file_id(url)
  return nil unless present?(url)

  return Regexp.last_match(1) if url =~ %r{drive\.google\.com/file/d/([^/]+)}
  return Regexp.last_match(1) if url =~ /[?&]id=([^&]+)/

  nil
end

def google_drive_download_url(url)
  return nil unless present?(url)

  if url =~ %r{drive\.google\.com/file/d/([^/]+)}
    "https://drive.google.com/uc?export=download&id=#{Regexp.last_match(1)}"
  elsif url =~ /[?&]id=([^&]+)/
    "https://drive.google.com/uc?export=download&id=#{Regexp.last_match(1)}"
  else
    url
  end
end

def source_label(source)
  source.is_a?(BibUrl) ? source.label || source.url : source
end

def read_bib_source(source)
  if source.is_a?(BibUrl)
    file_id = google_drive_file_id(source.url)
    text = if present?(file_id) && GoogleSheetsCsv.service_account_credentials
             token = GoogleSheetsCsv.access_token
             uri = URI("https://www.googleapis.com/drive/v3/files/#{file_id}?alt=media&supportsAllDrives=true")
             request = Net::HTTP::Get.new(uri)
             request["Authorization"] = "Bearer #{token}"
             response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
             abort_with("Could not download BibTeX from #{source.url}: #{response.code} #{response.body}") unless response.is_a?(Net::HTTPSuccess)

             response.body
           else
             URI.open(google_drive_download_url(source.url), &:read)
           end
    text = text.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace)
    if text.lstrip.start_with?("<!doctype html", "<html")
      abort_with("Could not download BibTeX from #{source.url}. Make the Google Drive file or folder readable by anyone with the link.")
    end

    text
  else
    File.read(source)
  end
end

def strip_outer_braces(value)
  text = value.to_s.strip
  loop do
    break unless text.start_with?("{") && text.end_with?("}")

    depth = 0
    balanced_outer = text.each_char.with_index.all? do |char, index|
      depth += 1 if char == "{"
      depth -= 1 if char == "}"
      depth.positive? || index == text.length - 1
    end
    break unless balanced_outer

    text = text[1...-1].strip
  end
  text
end

def clean_bib_value(value)
  strip_outer_braces(value)
    .sub(/\A"/, "")
    .sub(/"\z/, "")
    .gsub("\\_", "_")
    .gsub(/[{}]/, "")
    .gsub(/\s+/, " ")
    .strip
end

def split_fields(body)
  fields = []
  start = 0
  depth = 0
  quote = false

  body.each_char.with_index do |char, index|
    quote = !quote if char == '"' && body[index - 1] != "\\"
    depth += 1 if char == "{" && !quote
    depth -= 1 if char == "}" && !quote
    next unless char == "," && depth.zero? && !quote

    fields << body[start...index]
    start = index + 1
  end

  fields << body[start..]
  fields
end

def parse_bibtex(text)
  entries = []
  index = 0

  while (match = text.match(/@(\w+)\s*\{\s*([^,]+)\s*,/m, index))
    entry_type = match[1].downcase
    key = match[2].strip
    body_start = match.end(0)
    depth = 1
    cursor = body_start

    while cursor < text.length && depth.positive?
      char = text[cursor]
      depth += 1 if char == "{"
      depth -= 1 if char == "}"
      cursor += 1
    end

    body = text[body_start...(cursor - 1)]
    fields = split_fields(body).each_with_object({}) do |field, memo|
      field_match = field.match(/\A\s*([A-Za-z][A-Za-z0-9_-]*)\s*=\s*(.+?)\s*\z/m)
      next unless field_match

      memo[field_match[1].downcase] = clean_bib_value(field_match[2])
    end

    entries << {
      type: entry_type,
      key: key,
      raw: text[match.begin(0)...cursor].strip,
      fields: fields
    }
    index = cursor
  end

  entries
end

def authors_from(fields)
  fields["author"].to_s.split(/\s+and\s+/i).map(&:strip).join(", ")
end

def join_present(parts)
  parts.select { |part| present?(part) }.join(", ")
end

def year_from(fields)
  fields["year"].to_s[/\d{4}/] || fields["year"] || ""
end

def month_order_from(fields)
  month = fields["month"].to_s.downcase.strip
  return month.to_i if month.match?(/\A\d+\z/)

  {
    "jan" => 1,
    "january" => 1,
    "feb" => 2,
    "february" => 2,
    "mar" => 3,
    "march" => 3,
    "apr" => 4,
    "april" => 4,
    "may" => 5,
    "jun" => 6,
    "june" => 6,
    "jul" => 7,
    "july" => 7,
    "aug" => 8,
    "august" => 8,
    "sep" => 9,
    "sept" => 9,
    "september" => 9,
    "oct" => 10,
    "october" => 10,
    "nov" => 11,
    "november" => 11,
    "dec" => 12,
    "december" => 12
  }[month] || 0
end

def slugify(value)
  value.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-+\z/, "")
end

def bibtex_page_path(key)
  "/publications/bibtex/#{slugify(key)}/"
end

def article_from(key, fields, order, bibtex_entry)
  title = fields["title"]
  return nil unless present?(title)

  volume_number = if present?(fields["volume"]) && present?(fields["number"])
                    "vol. #{fields["volume"]}, no. #{fields["number"]}"
                  elsif present?(fields["volume"])
                    "vol. #{fields["volume"]}"
                  elsif present?(fields["number"])
                    "no. #{fields["number"]}"
                  end

  {
    "id" => key,
    "entry_type" => "article",
    "year" => year_from(fields),
    "month_order" => month_order_from(fields),
    "title" => title,
    "authors" => authors_from(fields),
    "journal" => fields["journal"] || "",
    "volume" => fields["volume"] || "",
    "number" => fields["number"] || "",
    "publisher" => join_present([fields["journal"], volume_number]),
    "doi" => fields["doi"] || "",
    "bibtex_url" => bibtex_page_path(key),
    "bibtex_source_url" => fields["biburl"] || "",
    "bibtex_entry" => bibtex_entry,
    "order" => order
  }.delete_if { |_key, value| value == "" }
end

def inproceedings_from(key, fields, order, bibtex_entry)
  title = fields["title"]
  return nil unless present?(title)

  {
    "id" => key,
    "entry_type" => "inproceedings",
    "year" => year_from(fields),
    "month_order" => month_order_from(fields),
    "title" => title,
    "authors" => authors_from(fields),
    "booktitle" => fields["booktitle"] || "",
    "series" => fields["series"] || "",
    "pages" => fields["pages"] || "",
    "publisher_name" => fields["publisher"] || "",
    "publisher" => join_present([
      fields["booktitle"],
      fields["series"],
      (present?(fields["pages"]) ? "pp. #{fields["pages"]}" : nil),
      fields["publisher"]
    ]),
    "doi" => fields["doi"] || "",
    "bibtex_url" => bibtex_page_path(key),
    "bibtex_source_url" => fields["biburl"] || "",
    "bibtex_entry" => bibtex_entry,
    "order" => order
  }.delete_if { |_key, value| value == "" }
end

def techreport_from(key, fields, order, bibtex_entry)
  title = fields["title"]
  return nil unless present?(title)

  {
    "id" => key,
    "entry_type" => "techreport",
    "year" => year_from(fields),
    "month_order" => month_order_from(fields),
    "title" => title,
    "authors" => authors_from(fields),
    "institution" => fields["institution"] || "",
    "report_type" => fields["type"] || "",
    "number" => fields["number"] || "",
    "publisher" => join_present([
      fields["institution"],
      fields["type"],
      fields["number"]
    ]),
    "doi" => fields["doi"] || "",
    "bibtex_url" => bibtex_page_path(key),
    "bibtex_source_url" => fields["biburl"] || "",
    "bibtex_entry" => bibtex_entry,
    "order" => order
  }.delete_if { |_key, value| value == "" }
end

def award_misc?(fields)
  fields.values.any? { |value| value.to_s.include?("受賞") }
end

def misc_award_from(key, fields, order, bibtex_entry)
  return nil unless award_misc?(fields)

  title = fields["title"]
  return nil unless present?(title)

  {
    "id" => key,
    "entry_type" => "award",
    "year" => year_from(fields),
    "month_order" => month_order_from(fields),
    "title" => title,
    "authors" => authors_from(fields),
    "howpublished" => fields["howpublished"] || "",
    "publisher" => join_present([
      fields["howpublished"]
    ]),
    "bibtex_url" => bibtex_page_path(key),
    "bibtex_source_url" => fields["biburl"] || "",
    "bibtex_entry" => bibtex_entry,
    "order" => order
  }.delete_if { |_key, value| value == "" }
end

def poster_misc?(fields)
  note = fields["note"].to_s.strip.downcase
  note == "poster" || fields["note"].to_s.strip == "ポスター"
end

def poster_misc_english?(fields)
  fields["note"].to_s.strip.downcase == "poster"
end

def misc_poster_from(key, fields, order, bibtex_entry)
  return nil unless poster_misc?(fields)

  title = fields["title"]
  return nil unless present?(title)

  {
    "id" => key,
    "entry_type" => "poster",
    "year" => year_from(fields),
    "month_order" => month_order_from(fields),
    "title" => title,
    "authors" => authors_from(fields),
    "howpublished" => fields["howpublished"] || "",
    "note" => fields["note"] || "",
    "show_on_english" => poster_misc_english?(fields),
    "publisher" => join_present([
      fields["howpublished"]
    ]),
    "doi" => fields["doi"] || "",
    "url" => fields["url"] || "",
    "bibtex_url" => bibtex_page_path(key),
    "bibtex_source_url" => fields["biburl"] || "",
    "bibtex_entry" => bibtex_entry,
    "order" => order
  }.delete_if { |_key, value| value == "" }
end

def publication_from(entry, order)
  case entry[:type]
  when "article"
    article_from(entry[:key], entry[:fields], order, entry[:raw])
  when "inproceedings"
    inproceedings_from(entry[:key], entry[:fields], order, entry[:raw])
  when "techreport"
    techreport_from(entry[:key], entry[:fields], order, entry[:raw])
  when "misc"
    misc_award_from(entry[:key], entry[:fields], order, entry[:raw]) ||
      misc_poster_from(entry[:key], entry[:fields], order, entry[:raw])
  end
end

def publication_sort_key(publication)
  [-publication["year"].to_i, -(publication["month_order"] || 0), publication["order"] || 999, publication["title"].to_s]
end

def public_publication(publication)
  publication.reject { |key, _value| key == "bibtex_entry" || key == "month_order" }
end

def japanese_text?(value)
  value.to_s.match?(/[\p{Hiragana}\p{Katakana}\p{Han}]/)
end

def show_on_english_publications?(publication)
  return false if publication["entry_type"] == "award"
  return publication["show_on_english"] if publication["entry_type"] == "poster"

  !(publication["entry_type"] == "techreport" && japanese_text?(publication["title"]))
end

def bibtex_page(publication, lang)
  back_label = lang == :en ? "Back to Publications" : "業績一覧へ戻る"
  back_path = lang == :en ? "/en/publications/" : "/publications/"
  permalink_prefix = lang == :en ? "/en/publications/bibtex" : "/publications/bibtex"
  escaped_bibtex = CGI.escapeHTML(publication["bibtex_entry"].to_s.strip)
  front_matter = {
    "title" => "#{publication["title"]} - BibTeX",
    "permalink" => "#{permalink_prefix}/#{slugify(publication["id"])}/"
  }
  front_matter["lang"] = "en" if lang == :en
  front_matter["site_title"] = "Yuen/Nakazawa Laboratory" if lang == :en

  <<~MARKDOWN
    #{front_matter.to_yaml}---

    <section class="page-header">
      <p class="eyebrow">BibTeX</p>
      <h1>BibTeX</h1>
      <p>#{publication["title"]}</p>
    </section>

    <section class="section">
      <div class="bibtex-entry">
        {% raw %}
        <pre><code>#{escaped_bibtex}</code></pre>
        {% endraw %}
      </div>
      <p><a class="member-card__link" href="{{ '#{back_path}' | relative_url }}">#{back_label}</a></p>
    </section>
  MARKDOWN
end

def write_bibtex_pages(publications)
  FileUtils.rm_rf("publications/bibtex")
  FileUtils.rm_rf("en/publications/bibtex")

  publications.each do |publication|
    next unless present?(publication["bibtex_entry"])

    slug = slugify(publication["id"])
    ja_path = File.join("publications", "bibtex", slug, "index.md")
    en_path = File.join("en", "publications", "bibtex", slug, "index.md")
    FileUtils.mkdir_p(File.dirname(ja_path))
    File.write(ja_path, bibtex_page(publication, :ja))
    if show_on_english_publications?(publication)
      FileUtils.mkdir_p(File.dirname(en_path))
      File.write(en_path, bibtex_page(publication, :en))
    end
  end
end

sources = bib_sources
abort_with("No BibTeX sources found. Set PUBLICATIONS_BIB_FOLDER_URL, PUBLICATIONS_BIB_FOLDER_ID, PUBLICATIONS_BIB_URLS, PUBLICATIONS_BIB_DIR, or PUBLICATIONS_BIB_FILES.") if sources.empty?

puts "BibTeX sources:"
sources.each { |source| puts "- #{source_label(source)}" }

seen = {}
publications = []
sources.each do |source|
  parse_bibtex(read_bib_source(source)).each do |entry|
    next if seen[entry[:key]]

    publication = publication_from(entry, publications.size + 1)
    next unless publication

    seen[entry[:key]] = true
    publications << publication
  end
end

publications = publications.sort_by { |publication| publication_sort_key(publication) }
abort_with("No @article, @inproceedings, @techreport, or award @misc entries found in BibTeX files.") if publications.empty?

FileUtils.mkdir_p("_data")
write_bibtex_pages(publications)
publications_data = publications.map { |publication| public_publication(publication) }
publications_en_data = publications
                       .select { |publication| show_on_english_publications?(publication) }
                       .map { |publication| public_publication(publication) }
File.write("_data/publications.yml", publications_data.to_yaml)
File.write("_data/publications_en.yml", publications_en_data.to_yaml)

puts "Synced #{publications.size} publications from #{sources.size} BibTeX sources."
