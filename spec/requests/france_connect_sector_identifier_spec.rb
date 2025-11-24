# voir https://docs.partenaires.franceconnect.gouv.fr/fs/fs-technique/fs-technique-sector_identifier/
# En ayant un même openid sub sur les deux instances, on peut faciliter la migration des usagers d'une instance à l'autre.
RSpec.describe "Secteur d'identification France Connect V2" do
  specify do
    get "/franceconnect_v2/sector_identifier"

    expect(response.parsed_body).to eq %w[
      http://www.rdv-solidarites-test.localhost/franceconnect_v2/callback
      http://www.rdv-aide-numerique-test.localhost/franceconnect_v2/callback
      http://www.rdv-service-public-test.localhost/franceconnect_v2/callback
    ]

    expect(response.headers["content-type"]).to eq "application/json"
  end
end
