#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "open-uri"

CSV_URL = ENV["NEWS_SHEET_CSV_URL"]
SHEET_ID = ENV["NEWS_SHEET_ID"]
SHEET_GID = ENV["NEWS_SHEET_GID"].to_s.empty? ? "0" : ENV["NEWS_SHEET_GID"]
GENERATED_MARKER = "<!-- generated-from-google-sheets -->"

def abort_with(message)
  warn(message)
  exit(1)
end

def present?(value)
  !value.nil? && !value.empty?
end

def spreadsheet_id_from(value)
  return nil unless present?(value)

  value[%r{/spreadsheets/d/([^/]+)}, 1] || value
end

def sheet_url
  return CSV_URL unless CSV_URL.nil? || CSV_URL.empty?
  return nil if SHEET_ID.nil? || SHEET_ID.empty?

  "https://docs.google.com/spreadsheets/d/#{spreadsheet_id_from(SHEET_ID)}/export?format=csv&gid=#{SHEET_GID}"
end

def value(row, key)
  header = row.headers.find { |item| item.to_s.strip == key }
  row[header]&.strip
end

def slugify(text)
  text.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-+\z/, "")
end

def news_item_from(row)
  title = value(row, "title_ja") || value(row, "title")
  date = value(row, "date")
  return nil unless present?(title) && present?(date)

  slug = value(row, "slug")
  slug = slugify(value(row, "title_en") || title) unless present?(slug)

  {
    "title" => title,
    "date" => date,
    "show_until" => value(row, "show_until"),
    "slug" => slug,
    "body" => value(row, "body_ja") || value(row, "body") || "",
    "order" => (value(row, "order") || "999").to_i
  }
end

def delete_generated_news
  Dir.glob("_news/*.md").each do |path|
    File.delete(path) if File.read(path).include?(GENERATED_MARKER)
  end
end

def write_news(item)
  FileUtils.mkdir_p("_news")
  date_prefix = item.fetch("date")
  path = "_news/#{date_prefix}-#{item.fetch("slug")}.md"
  front_matter = [
    "---",
    "layout: news",
    "title: #{item.fetch("title").inspect}",
    "date: #{date_prefix}"
  ]
  front_matter << %(show_until: #{item["show_until"].inspect}) if present?(item["show_until"])
  front_matter << "---"

  File.write(path, <<~MARKDOWN)
    #{front_matter.join("\n")}

    #{GENERATED_MARKER}

    #{item.fetch("body")}
  MARKDOWN
end

url = sheet_url
abort_with("Set NEWS_SHEET_CSV_URL or NEWS_SHEET_ID.") unless url

csv_text = URI.open(url, &:read)
rows = CSV.parse(csv_text, headers: true)
news_items = rows.map { |row| news_item_from(row) }.compact.sort_by { |item| [-item["date"].delete("-").to_i, item["order"]] }

abort_with("No news found in Google Sheets CSV.") if news_items.empty?

delete_generated_news
news_items.each { |item| write_news(item) }

puts "Synced #{news_items.size} Japanese news posts."
