class MetabaseApi
  class Error < StandardError; end

  HOST_URL = "https://rdv-service-public-metabase.osc-secnum-fr1.scalingo.io".freeze
  DATABASE_ID = 2 # l’ID de la base Prod ETL cf https://rdv-service-public-metabase.osc-secnum-fr1.scalingo.io/admin/databases

  def self.sql_query(query, raw_json: false)
    res = Typhoeus.post(
      "#{HOST_URL}/api/dataset/json",
      body: { query: { database: DATABASE_ID, native: { query: }, type: "native" }.to_json },
      headers: {
        "x-api-key" => ENV["METABASE_API_KEY"],
        "Content-Type" => "application/x-www-form-urlencoded",
        "Accept" => "application/json",
      }
    )
    if [200, 202].exclude?(res.code)
      raise Error, "Statut #{res.code} retourné par l’API metabase dataset/json : #{res.body}"
    end

    if raw_json
      res.body
    else
      JSON.parse(res.body)
    end
  end

  def self.authentication_present? = ENV["METABASE_API_KEY"].present?
end
