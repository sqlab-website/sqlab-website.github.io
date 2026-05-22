#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "open-uri"
require "yaml"

CSV_URL = ENV["PUBLICATIONS_SHEET_CSV_URL"]
SHEET_ID = ENV["PUBLICATIONS_SHEET_ID"]
SHEET_GID = ENV["PUBLICATIONS_SHEET_GID"].to_s.empty? ? "0" : ENV["PUBLICATIONS_SHEET_GID"]

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

def en_only?(row)
  value(row, "only_en") == "1" || value(row, "en_only") == "1"
end

def ja_only?(row)
  value(row, "only_en") == "0" || value(row, "en_only") == "0"
end

def publication_from(row, lang)
  use_english = lang == :en || en_only?(row)
  suffix = use_english ? "en" : "ja"
  title = value(row, "title_#{suffix}")
  if lang == :ja && !present?(title) && present?(value(row, "title_en"))
    use_english = true
    suffix = "en"
    title = value(row, "title_en")
  end
  return nil unless present?(title)
  return nil if lang == :en && ja_only?(row)

  {
    "id" => value(row, "id") || "",
    "year" => value(row, "year") || "",
    "title" => title,
    "authors" => value(row, "authors_#{suffix}") || "",
    "publisher" => value(row, "publisher_#{suffix}") || "",
    "doi" => value(row, "doi") || "",
    "order" => (value(row, "order") || "999").to_i
  }.delete_if { |_key, item| item == "" }
end

def publication_sort_key(publication)
  [-publication["year"].to_i, publication["order"] || 999, publication["title"].to_s]
end

def write_yaml(path, items)
  File.write(path, items.to_yaml)
end

url = sheet_url
abort_with("Set PUBLICATIONS_SHEET_CSV_URL or PUBLICATIONS_SHEET_ID.") unless url

csv_text = URI.open(url, &:read)
rows = CSV.parse(csv_text, headers: true)

publications_ja = rows.filter_map { |row| publication_from(row, :ja) }.sort_by { |publication| publication_sort_key(publication) }
publications_en = rows.filter_map { |row| publication_from(row, :en) }.sort_by { |publication| publication_sort_key(publication) }

abort_with("No publications found in Google Sheets CSV.") if publications_ja.empty? && publications_en.empty?

FileUtils.mkdir_p("_data")
write_yaml("_data/publications.yml", publications_ja)
write_yaml("_data/publications_en.yml", publications_en)

puts "Synced #{publications_ja.size} Japanese publications and #{publications_en.size} English publications."
