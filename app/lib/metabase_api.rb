class MetabaseApi
  class Error < StandardError; end

  HOST_URL = "https://rdv-service-public-metabase.osc-secnum-fr1.scalingo.io".freeze
  DATABASE_ID = 2 # l’ID de la base Prod ETL cf https://rdv-service-public-metabase.osc-secnum-fr1.scalingo.io/admin/databases

  def self.sql_query(query, raw_json: false, timeout: HttpClient::DEFAULT_TIMEOUT)
    connection = HttpClient.connection(
      url: HOST_URL,
      basic_auth: "#{ENV['METABASE_BASIC_AUTH_USER']}:#{ENV['METABASE_BASIC_AUTH_PASSWORD']}",
      headers: {
        "x-api-key" => ENV["METABASE_API_KEY"].to_s,
        "Content-Type" => "application/json",
        "Accept" => "application/json",
      },
      timeout:
    )
    res = connection.post(
      "/api/dataset/json",
      { query: { database: DATABASE_ID, native: { query: }, type: "native" } }.to_json
    )
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
