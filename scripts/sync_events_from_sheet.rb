#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "open-uri"
require "yaml"

CSV_URL = ENV["EVENTS_SHEET_CSV_URL"]
SHEET_ID = ENV["EVENTS_SHEET_ID"]
SHEET_GID = ENV["EVENTS_SHEET_GID"].to_s.empty? ? "0" : ENV["EVENTS_SHEET_GID"]

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
  row[key]&.strip
end

def event_from(row, lang)
  suffix = lang == :ja ? "ja" : "en"
  title = value(row, "title_#{suffix}")
  return nil unless present?(title)

  {
    "date" => value(row, "date") || "",
    "type" => value(row, "type_#{suffix}") || value(row, "type") || "",
    "title" => title,
    "time" => value(row, "time") || "",
    "place" => value(row, "place_#{suffix}") || value(row, "place") || "",
    "description" => value(row, "description_#{suffix}") || "",
    "order" => (value(row, "order") || "999").to_i
  }.delete_if { |_key, item| item == "" }
end

def write_yaml(path, items)
  File.write(path, items.to_yaml)
end

url = sheet_url
abort_with("Set EVENTS_SHEET_CSV_URL or EVENTS_SHEET_ID.") unless url

csv_text = URI.open(url, &:read)
rows = CSV.parse(csv_text, headers: true)

events_ja = rows.filter_map { |row| event_from(row, :ja) }.sort_by { |event| [event["order"], event["date"].to_s] }
events_en = rows.filter_map { |row| event_from(row, :en) }.sort_by { |event| [event["order"], event["date"].to_s] }

abort_with("No events found in Google Sheets CSV.") if events_ja.empty? && events_en.empty?

FileUtils.mkdir_p("_data")
write_yaml("_data/events.yml", events_ja)
write_yaml("_data/events_en.yml", events_en)

puts "Synced #{events_ja.size} Japanese events and #{events_en.size} English events."
