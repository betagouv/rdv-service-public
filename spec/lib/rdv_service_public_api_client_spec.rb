RSpec.describe RdvServicePublicApiClient do
  stub_env_with RDV_SERVICE_PUBLIC_OAUTH_BASE_URL: "http://rdv.localhost"

  context "pour une requête qui renvoie une erreur 500" do
    before do
      stub_request(:post, "http://rdv.localhost/api/v1/plage_ouvertures")
        .to_return(
          status: 500,
          headers: { "Content-Type": "application/json" },
          body: { errors: ["Unexpected internal error"] }.to_json
        )
    end

    it "lève une exception" do
      expect do
        described_class.new("123456").post("plage_ouvertures", { lieu_external_ids: "asdf" })
      end.to raise_error(RdvServicePublicApiClient::RequestError)
    end
  end

  context "pour une requête qui échoue avec un statut 404" do
    before do
      stub_request(:post, "http://rdv.localhost/api/v1/plage_ouvertures")
        .to_return(
          status: 404,
          headers: { "Content-Type": "application/json" },
          body: { error_message: ["Aucun lieu trouvé pour le lieu_external_id 123456"] }.to_json
        )
    end

    it "ajoute la requête et la réponse HTTP en breadcrumb Sentry et lève une exception" do
      expect do
        described_class.new("123456").post("plage_ouvertures", { lieu_external_ids: "asdf" })
      end.to raise_error(RdvServicePublicApiClient::RequestError) do |e|
        Sentry.capture_exception(e)
        request_breadcrumb, response_breadcrumb = sentry_events.last.breadcrumbs.compact
        expect(request_breadcrumb.data[:body]).to eq({ lieu_external_ids: "asdf" }.to_json)
        expect(response_breadcrumb.data[:body]).to eq({ error_message: ["Aucun lieu trouvé pour le lieu_external_id 123456"] }.to_json)
      end
    end
  end

  context "pour une requête qui échoue à cause d'une erreur métier avec un statut 422" do
    before do
      stub_request(:post, "http://rdv.localhost/api/v1/motifs")
        .to_return(
          status: 422,
          headers: { "Content-Type": "application/json" },
          body: ApiSpecHelper.invalid_motif_response.to_json
        )
    end

    it "ne lève pas d'exception, mais renvoie la réponse pour que laisser le code client traiter l'erreur métier" do
      response = described_class.new("123456").post("motifs", {}) # Les paramètres ne sont pas utilisés pas le stub, donc on ne les précise pas
      expect(response).to eq({
                               "error_messages" => ['base Il existe déjà dans Mon Organisation un motif Sur place nommé "Suivi de dossier" ouvert à tous les agents'],
                               "errors" => { "base" => [{ "error" => "duplicate_detected" }] },
                             })
    end
  end

  context "pour une requête qui échoue parce que la ressource existe déjà" do
    before do
      stub_request(:post, "http://rdv.localhost/api/v1/motifs")
        .to_return(
          status: 422,
          headers: { "Content-Type": "application/json" },
          body: ApiSpecHelper.external_id_error_response.to_json
        )
    end

    it "n'échoue pas, parce qu'on veut permettre de faire plusieurs fois des copies de données inter-instances sans doublons et sans lever d'erreur" do
      response = described_class.new("123456").post("motifs", {}) # Les paramètres ne sont pas utilisés pas le stub, donc on ne les précise pas
      expect(response).to eq(
        { "error_messages" => ["external_id est déjà utilisé"], "errors" => { "external_id" => [{ "error" => "taken", "value" => "123ABC" }] } }
      )
    end
  end
end
