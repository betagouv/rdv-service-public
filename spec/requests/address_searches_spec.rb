RSpec.describe "Recherche d'adresse sur la page d'accueil", type: :request do
  let(:host) { "http://www.rdv-solidarites-test.localhost" }
  let(:query) { "79 rue de plaisance garenne" }

  it "redirige directement vers la suite de la prise de RDV quand un seul résultat a un score élevé" do
    stub_geocoding_search(query, ban_feature_79_rue_de_plaisance(score: 0.95), ban_feature_rue_de_plaisance_nogent(score: 0.5))

    get "#{host}/prendre_rdv/adresse", params: { address: query, prescripteur: 1 }

    expect(response).to redirect_to(prendre_rdv_path(
                                      address: "79 Rue de Plaisance, La Garenne-Colombes, 92250", departement: "92", city_code: "92035",
                                      street_ban_id: "92035_7180", latitude: 48.9, longitude: 2.25, prescripteur: "1"
                                    ))
    expect(flash[:notice]).to include("Adresse retenue : 79 Rue de Plaisance, La Garenne-Colombes, 92250")
  end

  it "affiche les adresses à choisir quand aucun résultat ne se détache" do
    stub_geocoding_search(query, ban_feature_79_rue_de_plaisance(score: 0.6), ban_feature_rue_de_plaisance_nogent(score: 0.5))

    get "#{host}/prendre_rdv/adresse", params: { address: query }

    expect(response).to be_successful
    expect(response.body).to include("2 adresses correspondent à « #{query} »")
    expect(response.body).to include("79 Rue de Plaisance, La Garenne-Colombes, 92250")
    expect(response.body).to include("Rue de Plaisance, Nogent-sur-Marne, 94130")
  end

  it "indique quand aucune adresse ne correspond" do
    stub_geocoding_search(query)

    get "#{host}/prendre_rdv/adresse", params: { address: query }

    expect(response.body).to include("Aucune adresse ne correspond à « #{query} »")
  end

  it "indique quand le service de recherche est indisponible" do
    stub_request(:get, "https://data.geopf.fr/geocodage/search/").with(query: { q: query, limit: 5 }).to_return(status: 503)

    get "#{host}/prendre_rdv/adresse", params: { address: query }

    expect(response.body).to include("Le service de recherche d’adresse est momentanément indisponible.")
  end

  it "demande de saisir une adresse quand le champ est vide" do
    get "#{host}/prendre_rdv/adresse", params: { address: " " }

    expect(response.body).to include("Saisissez votre adresse pour rechercher un rendez-vous")
    expect(WebMock).not_to have_requested(:get, /data.geopf.fr/)
  end

  it "n'est pas disponible sur les domaines sans sélection d'adresse" do
    get "http://www.rdv-service-public-test.localhost/prendre_rdv/adresse", params: { address: query }

    expect(response).to redirect_to(root_path)
  end

  context "avec rack-attack activé" do
    include_context "enable rack-attack"

    it "limite le nombre de recherches par IP" do
      stub_geocoding_search(query)

      2.times do
        get "#{host}/prendre_rdv/adresse", params: { address: query }
        expect(response).to be_successful
      end

      get "#{host}/prendre_rdv/adresse", params: { address: query }
      expect(response).to redirect_to("/500.html")
    end
  end
end
