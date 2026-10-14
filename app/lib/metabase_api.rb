class MetabaseApi
  class Error < StandardError; end

  HOST_URL = "https://rdv-service-public-metabase.osc-secnum-fr1.scalingo.io".freeze
  DATABASE_ID = 2 # l’ID de la base Prod ETL cf https://rdv-service-public-metabase.osc-secnum-fr1.scalingo.io/admin/databases

  def self.sql_query(query, raw_json: false, timeout: nil)
    headers = {
      "Authorization" => Faraday::Utils.basic_header_from(ENV["METABASE_BASIC_AUTH_USER"].to_s, ENV["METABASE_BASIC_AUTH_PASSWORD"].to_s),
      "x-api-key" => ENV["METABASE_API_KEY"].to_s,
      "Content-Type" => "application/json",
      "Accept" => "application/json",
    }
    body = { query: { database: DATABASE_ID, native: { query: }, type: "native" } }.to_json

    res = Faraday.post("#{HOST_URL}/api/dataset/json", body, headers) do |req|
      req.options.timeout = timeout if timeout
    end
    if res.status != 200
      raise Error, "Statut #{res.status} retourné par l’API metabase dataset/json"
    end

    if raw_json
      res.body
    else
      JSON.parse(res.body)
    end
  end

  def self.authentication_present? = ENV["METABASE_API_KEY"].present? && ENV["METABASE_BASIC_AUTH_USER"].present? && ENV["METABASE_BASIC_AUTH_PASSWORD"].present?
end
