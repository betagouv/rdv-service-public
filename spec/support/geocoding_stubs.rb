def stub_geocoding_search(query, *features)
  stub_request(:get, "https://data.geopf.fr/geocodage/search/")
    .with(query: { q: query, limit: 5 })
    .to_return(status: 200, body: { type: "FeatureCollection", features: }.to_json)
end

def ban_feature(name:, city:, postcode:, citycode:, id:, context:, type: "housenumber", score: 0.95, coordinates: [2.25, 48.9])
  {
    type: "Feature",
    geometry: { type: "Point", coordinates: },
    properties: { name:, city:, postcode:, citycode:, id:, context:, type:, score: },
  }
end

def ban_feature_79_rue_de_plaisance(score: 0.95)
  ban_feature(
    name: "79 Rue de Plaisance", city: "La Garenne-Colombes", postcode: "92250", citycode: "92035",
    id: "92035_7180_00079", context: "92, Hauts-de-Seine, Île-de-France", score:
  )
end

def ban_feature_rue_de_plaisance_nogent(score: 0.6)
  ban_feature(
    name: "Rue de Plaisance", city: "Nogent-sur-Marne", postcode: "94130", citycode: "94052",
    id: "94052_0750", context: "94, Val-de-Marne, Île-de-France", type: "street", score:
  )
end
