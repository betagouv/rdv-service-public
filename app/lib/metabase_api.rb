class MetabaseApi
  class Error < StandardError; end

  HOST_URL = "https://rdv-service-public-metabase.osc-secnum-fr1.scalingo.io".freeze
  DATABASE_ID = 2 # l’ID de la base Prod ETL cf https://rdv-service-public-metabase.osc-secnum-fr1.scalingo.io/admin/databases

  def self.sql_query(query)
    res = Typhoeus.post(
      "#{HOST_URL}/api/dataset/json",
      params: { query: { database: DATABASE_ID, native: { query: }, type: "native" }.to_json },
      headers: {
        "x-api-key" => ENV["METABASE_API_KEY"],
        "Content-Type" => "application/json",
        "Accept" => "application/json",
      }
    )
    if res.code != 200
      raise Error, "Statut #{res.code} retourné par l’API metabase dataset/json"
    end

    res.body
  end
end
