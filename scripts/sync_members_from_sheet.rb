#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "digest"
require "fileutils"
require "open-uri"
require "yaml"

CSV_URL = ENV["MEMBERS_SHEET_CSV_URL"]
SHEET_ID = ENV["MEMBERS_SHEET_ID"]
SHEET_GID = ENV["MEMBERS_SHEET_GID"].to_s.empty? ? "0" : ENV["MEMBERS_SHEET_GID"]

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

def google_drive_download_url(url)
  return nil unless present?(url)

  if url =~ %r{drive\.google\.com/file/d/([^/]+)}
    "https://drive.google.com/uc?export=download&id=#{Regexp.last_match(1)}"
  elsif url =~ /[?&]id=([^&]+)/
    "https://drive.google.com/uc?export=download&id=#{Regexp.last_match(1)}"
  elsif url =~ %r{docs\.google\.com/document/d/([^/]+)}
    "https://docs.google.com/document/d/#{Regexp.last_match(1)}/export?format=txt"
  else
    url
  end
end

def google_drive_view_url(url)
  return nil unless present?(url)

  if url =~ %r{drive\.google\.com/file/d/([^/]+)}
    "https://drive.google.com/file/d/#{Regexp.last_match(1)}/view?usp=sharing"
  elsif url =~ /[?&]id=([^&]+)/
    "https://drive.google.com/file/d/#{Regexp.last_match(1)}/view?usp=sharing"
  elsif url =~ %r{docs\.google\.com/document/d/([^/]+)}
    "https://docs.google.com/document/d/#{Regexp.last_match(1)}/edit?usp=sharing"
  else
    url
  end
end

def google_drive_image_url(url)
  return nil unless present?(url)

  if url =~ %r{drive\.google\.com/file/d/([^/]+)}
    "https://drive.google.com/thumbnail?id=#{Regexp.last_match(1)}&sz=w640"
  elsif url =~ /[?&]id=([^&]+)/
    "https://drive.google.com/thumbnail?id=#{Regexp.last_match(1)}&sz=w640"
  else
    url
  end
end

def fetch_markdown(url)
  return nil unless present?(url)

  URI.open(google_drive_download_url(url), &:read).force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace)
rescue OpenURI::HTTPError, SocketError, URI::InvalidURIError => error
  warn("Could not fetch profile markdown from #{url}: #{error.message}")
  nil
end

def image_extension(content_type)
  {
    "image/jpeg" => ".jpg",
    "image/png" => ".png",
    "image/gif" => ".gif",
    "image/webp" => ".webp"
  }[content_type]
end

def fetch_photo(url, slug)
  return nil unless present?(url)

  URI.open(google_drive_download_url(url), "rb") do |file|
    extension = image_extension(file.content_type)
    unless extension
      warn("Could not fetch member photo from #{url}: unsupported content type #{file.content_type}")
      return nil
    end

    FileUtils.mkdir_p("assets/images/members")
    filename = "#{slug}-#{Digest::SHA1.hexdigest(url)[0, 8]}#{extension}"
    path = File.join("assets/images/members", filename)
    File.binwrite(path, file.read)
    "/#{path}"
  end
rescue OpenURI::HTTPError, SocketError, URI::InvalidURIError => error
  warn("Could not fetch member photo from #{url}: #{error.message}")
  nil
end

def strip_front_matter(markdown)
  markdown.to_s.sub(/\A---\s*\n.*?\n---\s*\n/m, "").strip
end

def member_from(row, lang)
  suffix = lang == :ja ? "ja" : "en"
  name = value(row, "name_#{suffix}")
  return nil unless present?(name)

  order = (value(row, "order") || "999").to_i
  return nil if order.zero?

  slug = value(row, "slug")
  slug = slugify(value(row, "name_en") || name) unless present?(slug)

  {
    "name" => name,
    "slug" => slug,
    "initial" => value(row, "initial") || name[0],
    "role" => value(row, "role_#{suffix}") || "",
    "theme" => value(row, "theme_#{suffix}") || "",
    "bio" => value(row, "bio_#{suffix}") || "",
    "email" => value(row, "email") || "",
    "website" => value(row, "website_#{suffix}") || value(row, "web") || value(row, "website") || "",
    "photo_url" => value(row, "photo_url") || "",
    "profile_md_url" => value(row, "profile_md_#{suffix}_url") || "",
    "order" => order
  }.delete_if { |_key, item| item == "" }
end

def front_matter(data)
  data.to_yaml.sub(/\A---\n/, "---\n")
end

def write_yaml(path, members)
  File.write(path, members.to_yaml)
end

def write_profile(path, member, lang:)
  FileUtils.mkdir_p(File.dirname(path))
  is_en = lang == :en
  prefix = is_en ? "/en/members" : "/members"
  title = member.fetch("name")
  role = member["role"]
  theme = member["theme"]
  bio = member["bio"]
  initial = member["initial"]
  permalink = "#{prefix}/#{member.fetch("slug")}/"
  site_title = is_en ? "Yuen/Nakazawa Laboratory" : nil

  metadata = {
    "title" => title,
    "permalink" => permalink
  }
  metadata["lang"] = "en" if is_en
  metadata["site_title"] = site_title if site_title

  heading = is_en ? "Member" : "Member"
  theme_label = is_en ? "Research Theme" : "Research Theme"
  email_label = is_en ? "Email" : "メール"
  personal_site_label = is_en ? "Personal Page" : "個人ページ"
  profile_label = is_en ? "Profile" : "profile"
  personal_site_text = is_en ? "Open personal page" : "個人ページを開く"
  profile_text = is_en ? "Open profile" : "profileを開く"
  profile_markdown = strip_front_matter(fetch_markdown(member["profile_md_url"]))

  contact_lines = []
  if member["email"]
    email = member["email"]
    email_html = email.include?("@") ? "<a href=\"mailto:#{email}\">#{email}</a>" : email
    contact_lines << "<p><strong>#{email_label}</strong><br>#{email_html}</p>"
  end
  media_html = if member["photo_url"]
                 photo_src = fetch_photo(member["photo_url"], member.fetch("slug")) || google_drive_image_url(member["photo_url"])
                 "<img class=\"profile-photo\" src=\"#{photo_src}\" alt=\"#{title}\">"
               else
                 "<div class=\"avatar avatar--large\" aria-hidden=\"true\">#{initial}</div>"
               end
  external_links = []
  external_links << [personal_site_label, personal_site_text, member["website"]] if member["website"]
  external_links << [profile_label, profile_text, google_drive_view_url(member["profile_md_url"])] if member["profile_md_url"] && !present?(profile_markdown)
  links_content = if external_links.any?
                    link_items = external_links.map do |label, text, href|
                      <<~HTML
                        <p><strong>#{label}</strong><br><a class="button" href="#{href}">#{text}</a></p>
                      HTML
                    end.join("\n")
                    <<~HTML
                      <div class="profile-block profile-block--compact">
                        <p class="eyebrow">Links</p>
                        #{link_items}
                      </div>
                    HTML
                  else
                    ""
                  end
  profile_content = if present?(profile_markdown)
                      <<~HTML
                        <div class="profile-block profile-markdown" markdown="1">
                        #{profile_markdown}
                        </div>
                        #{links_content.rstrip}
                      HTML
                    elsif external_links.any?
                      links_content
                    else
                      <<~HTML
                        <div class="profile-block">
                          <p class="eyebrow">#{theme_label}</p>
                          <h2>#{theme}</h2>
                          <p>#{bio}</p>
                        </div>
                      HTML
                    end

  File.write(path, <<~MARKDOWN)
    #{front_matter(metadata)}
    ---

    <section class="page-header">
      <p class="eyebrow">#{heading}</p>
      <h1>#{title}</h1>
      <p>#{role}</p>
    </section>

    <section class="section member-profile">
      #{media_html}
      <div class="member-profile__body">
        #{profile_content.rstrip}
        #{external_links.any? || contact_lines.empty? ? "" : "<div class=\"profile-block profile-block--compact\">\n          <p class=\"eyebrow\">Contact</p>\n          #{contact_lines.join("\n          ")}\n        </div>"}
        <a class="back-link" href="#{is_en ? "/en/members/" : "/members/"}">#{is_en ? "Back to Members" : "メンバー一覧へ"}</a>
      </div>
    </section>
  MARKDOWN
end

url = sheet_url
abort_with("Set MEMBERS_SHEET_CSV_URL or MEMBERS_SHEET_ID.") unless url

csv_text = URI.open(url, &:read).force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace)
rows = CSV.parse(csv_text, headers: true)

members_ja = rows.map { |row| member_from(row, :ja) }.compact.sort_by { |member| member["order"] }
members_en = rows.map { |row| member_from(row, :en) }.compact.sort_by { |member| member["order"] }

abort_with("No members found in Google Sheets CSV.") if members_ja.empty? && members_en.empty?

FileUtils.mkdir_p("_data")
write_yaml("_data/members.yml", members_ja)
write_yaml("_data/members_en.yml", members_en)

members_ja.each { |member| write_profile("members/#{member.fetch("slug")}.md", member, lang: :ja) }
members_en.each { |member| write_profile("en/members/#{member.fetch("slug")}.md", member, lang: :en) }

puts "Synced #{members_ja.size} Japanese members and #{members_en.size} English members."
