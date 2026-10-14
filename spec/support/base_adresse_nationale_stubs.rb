# Les requêtes de l’autocomplétion d’adresse sont faites par le navigateur (fetch) :
# WebMock ne les voit pas, il faut les intercepter avec Playwright (cf AGENTS.md).
def stub_base_adresse_nationale_autocomplete_request(results: "16_quai_de_la_loire", sleep: 0, abort: false)
  body =
    if results == []
      { type: "FeatureCollection", features: [] }.to_json
    elsif results == "16_quai_de_la_loire"
      file_fixture("base_adresse_nationale_search_#{results}.json").read
    else
      raise ArgumentError, "results doit être [] ou \"16_quai_de_la_loire\", reçu : #{results.inspect}"
    end

  page.driver.with_playwright_page do |playwright_page|
    playwright_page.route("https://data.geopf.fr/geocodage/search/**", lambda { |route, _request|
      sleep(sleep) if sleep.positive?
      if abort
        route.abort
      else
        route.fulfill(status: 200, contentType: "application/json", body: body)
      end
    })
  end
end
