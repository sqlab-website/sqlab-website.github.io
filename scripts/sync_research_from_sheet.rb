#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "open-uri"
require "yaml"
require_relative "google_sheets_csv"

CSV_URL = ENV["RESEARCH_SHEET_CSV_URL"]
SHEET_ID = ENV["RESEARCH_SHEET_ID"]
SHEET_GID = ENV["RESEARCH_SHEET_GID"].to_s.empty? ? "0" : ENV["RESEARCH_SHEET_GID"]

def abort_with(message)
  warn(message)
  exit(1)
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
  row[key]&.strip
end

def present?(value)
  !value.nil? && !value.empty?
end

def slugify(text)
  text.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-+\z/, "")
end

def split_tags(text)
  return [] unless present?(text)

  text.split(/[,\n、]/).map(&:strip).reject(&:empty?)
end

def research_from(row, lang)
  suffix = lang == :ja ? "ja" : "en"
  title = value(row, "title_#{suffix}")
  return nil unless present?(title)

  id = value(row, "id")
  id = slugify(value(row, "title_en") || title) unless present?(id)

  area = value(row, "area_#{suffix}") || value(row, "area") || ""
  summary = value(row, "summary_#{suffix}") || ""
  description = value(row, "description_#{suffix}") || summary
  tags = split_tags(value(row, "tags_#{suffix}") || value(row, "tags"))

  {
    "id" => id,
    "area" => area,
    "title" => title,
    "summary" => summary,
    "description" => description,
    "tags" => tags,
    "order" => (value(row, "order") || "999").to_i
  }.delete_if { |_key, item| item == "" || item == [] }
end

def write_yaml(path, items)
  File.write(path, items.to_yaml)
end

abort_with("Set RESEARCH_SHEET_CSV_URL or RESEARCH_SHEET_ID.") unless present?(CSV_URL) || present?(SHEET_ID)

csv_text = GoogleSheetsCsv.fetch(csv_url: CSV_URL, sheet_id: SHEET_ID, gid: SHEET_GID)
rows = CSV.parse(csv_text, headers: true)

research_ja = rows.map { |row| research_from(row, :ja) }.compact.sort_by { |item| item["order"] }
research_en = rows.map { |row| research_from(row, :en) }.compact.sort_by { |item| item["order"] }

abort_with("No research topics found in Google Sheets CSV.") if research_ja.empty? && research_en.empty?

FileUtils.mkdir_p("_data")
write_yaml("_data/research.yml", research_ja)
write_yaml("_data/research_en.yml", research_en)

puts "Synced #{research_ja.size} Japanese research topics and #{research_en.size} English research topics."
