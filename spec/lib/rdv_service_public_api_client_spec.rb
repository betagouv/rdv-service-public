RSpec.describe RdvServicePublicApiClient do
  stub_env_with RDV_SERVICE_PUBLIC_OAUTH_BASE_URL: "http://rdv.localhost"

  context "pour une requête qui échoue" do
    before do
      stub_request(:post, "http://rdv.localhost/api/v1/plage_ouvertures")
        .to_return(
          status: 404,
          headers: { "Content-Type": "application/json" },
          body: { error_message: ["Aucun lieu trouvé pour le lieu_external_id 123456"] }.to_json
        )
    end

    it "ajoute la requête et la réponse HTTP en breadcrumb Sentry et lève une exception" do
      client = described_class.new("123456")
      expect do
        client.post("plage_ouvertures", { lieu_external_ids: "asdf" })
      end.to raise_error(Faraday::ResourceNotFound) do |e|
        Sentry.capture_exception(e)
        request_breadcrumb, response_breadcrumb = sentry_events.last.breadcrumbs.compact
        expect(request_breadcrumb.data[:body]).to eq({ lieu_external_ids: "asdf" }.to_json)
        expect(response_breadcrumb.data[:body]).to eq({ error_message: ["Aucun lieu trouvé pour le lieu_external_id 123456"] }.to_json)
      end
    end
  end
end
