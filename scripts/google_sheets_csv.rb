# frozen_string_literal: true

require "base64"
require "csv"
require "json"
require "net/http"
require "openssl"
require "open-uri"
require "uri"

module GoogleSheetsCsv
  SCOPE = "https://www.googleapis.com/auth/spreadsheets.readonly https://www.googleapis.com/auth/drive.readonly"
  DEFAULT_TOKEN_URI = "https://oauth2.googleapis.com/token"

  module_function

  def fetch(csv_url:, sheet_id:, gid:)
    if present?(csv_url)
      return URI.open(csv_url, &:read).force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace)
    end

    spreadsheet_id = spreadsheet_id_from(sheet_id)
    raise "Set a Google Sheets spreadsheet ID." unless present?(spreadsheet_id)

    if service_account_credentials
      fetch_with_service_account(spreadsheet_id, gid)
    else
      url = "https://docs.google.com/spreadsheets/d/#{spreadsheet_id}/export?format=csv&gid=#{gid}"
      URI.open(url, &:read).force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace)
    end
  end

  def fetch_with_service_account(spreadsheet_id, gid)
    token = access_token
    sheet_title = sheet_title_for_gid(spreadsheet_id, gid, token)
    values = sheet_values(spreadsheet_id, sheet_title, token)

    CSV.generate do |csv|
      values.each { |row| csv << row }
    end
  end

  def sheet_title_for_gid(spreadsheet_id, gid, token)
    uri = URI("https://sheets.googleapis.com/v4/spreadsheets/#{spreadsheet_id}")
    uri.query = URI.encode_www_form(fields: "sheets(properties(sheetId,title))")
    data = get_json(uri, token)
    sheets = data.fetch("sheets", []).map { |sheet| sheet.fetch("properties", {}) }
    sheet = sheets.find { |properties| properties["sheetId"].to_s == gid.to_s } || sheets.first
    raise "No sheets found in spreadsheet #{spreadsheet_id}." unless sheet

    sheet.fetch("title")
  end

  def sheet_values(spreadsheet_id, sheet_title, token)
    range = "'#{sheet_title.gsub("'", "''")}'!A:ZZ"
    encoded_range = URI.encode_www_form_component(range)
    uri = URI("https://sheets.googleapis.com/v4/spreadsheets/#{spreadsheet_id}/values/#{encoded_range}")
    data = get_json(uri, token)
    data.fetch("values", [])
  end

  def get_json(uri, token)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{token}"
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    raise "Google Sheets API request failed: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def access_token
    credentials = service_account_credentials
    now = Time.now.to_i
    assertion = jwt_assertion(credentials, now)
    uri = URI(credentials["token_uri"] || DEFAULT_TOKEN_URI)
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(
      "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
      "assertion" => assertion
    )
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    raise "Service account token request failed: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).fetch("access_token")
  end

  def jwt_assertion(credentials, now)
    header = { "alg" => "RS256", "typ" => "JWT" }
    claim = {
      "iss" => credentials.fetch("client_email"),
      "scope" => SCOPE,
      "aud" => credentials["token_uri"] || DEFAULT_TOKEN_URI,
      "iat" => now,
      "exp" => now + 3600
    }
    signing_input = [header, claim].map { |part| base64url(JSON.generate(part)) }.join(".")
    private_key = OpenSSL::PKey::RSA.new(credentials.fetch("private_key"))
    signature = private_key.sign(OpenSSL::Digest::SHA256.new, signing_input)

    "#{signing_input}.#{base64url(signature)}"
  end

  def service_account_credentials
    json = ENV["GOOGLE_SERVICE_ACCOUNT_JSON"]
    json = Base64.decode64(ENV["GOOGLE_SERVICE_ACCOUNT_JSON_BASE64"]) if !present?(json) && present?(ENV["GOOGLE_SERVICE_ACCOUNT_JSON_BASE64"])
    json = File.read(ENV["GOOGLE_APPLICATION_CREDENTIALS"]) if !present?(json) && present?(ENV["GOOGLE_APPLICATION_CREDENTIALS"])
    return nil unless present?(json)

    JSON.parse(json)
  end

  def spreadsheet_id_from(value)
    return nil unless present?(value)

    value[%r{/spreadsheets/d/([^/]+)}, 1] || value
  end

  def base64url(value)
    Base64.urlsafe_encode64(value).delete("=")
  end

  def present?(value)
    !value.nil? && !value.to_s.empty?
  end
end
