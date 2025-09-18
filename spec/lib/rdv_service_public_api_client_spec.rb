RSpec.describe RdvServicePublicApiClient do
  stub_env_with RDV_SERVICE_PUBLIC_OAUTH_BASE_URL: "http://rdv.localhost"

  context "pour une requête qui échoue" do
    before do
      stub_request(:post, "http://rdv.localhost/api/v1/plage_ouvertures")
        .to_return(
          status: 404,
          headers: { "Content-Type": "application/json" },
          body: { error_message: ["Aucun lieu trouvé pour le lieux_external_id 123456"] }.to_json
        )
    end

    it "envoie un message dans Sentry avec des breadcrumbs qui indiquent les valeurs de l'appel HTTP" do
      client = described_class.new("123456")
      client.post("plage_ouvertures", { lieu_external_ids: "asdf" })

      expect(sentry_events.last.message).to eq("Erreur lors de l'appel à l'api de RDV Service Public")
      expect(sentry_events.last.breadcrumbs.first.data[:body]).to include("lieu_external_id")
    end
  end
end
