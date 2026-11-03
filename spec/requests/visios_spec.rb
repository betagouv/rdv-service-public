RSpec.describe "Accès à la visioconférence d'un RDV via le lien avec token", type: :request do
  let(:motif) { create(:motif, location_type: :visio) }
  let(:rdv) { create(:rdv, motif:, organisation: motif.organisation, lieu: nil, visio_url_custom:) }
  let(:visio_url_custom) { "https://visio.numerique.gouv.fr/salon" }

  it "redirige vers le salon sans être connecté" do
    get visio_from_token_path(rdv.signed_id(purpose: :visio))

    expect(response).to redirect_to("https://visio.numerique.gouv.fr/salon")
  end

  context "quand le lien de visio n'a pas encore été généré" do
    let(:visio_url_custom) { nil }

    it "invite à revenir ultérieurement" do
      get visio_from_token_path(rdv.signed_id(purpose: :visio))

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Le lien de visioconférence n’est pas encore disponible : revenez ultérieurement pour l’obtenir.")
    end
  end

  context "quand le RDV a été annulé" do
    before { rdv.update!(status: "excused") }

    it "ne redirige pas vers le salon" do
      get visio_from_token_path(rdv.signed_id(purpose: :visio))

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ce rendez-vous n’a pas de visioconférence associée.")
      expect(response.body).not_to include("https://visio.numerique.gouv.fr/salon")
    end
  end

  it "ne trouve pas le RDV avec un token invalide" do
    expect { get visio_from_token_path("token-invalide") }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "ne trouve pas le RDV avec un token signé pour un autre usage" do
    expect { get visio_from_token_path(rdv.signed_id) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
