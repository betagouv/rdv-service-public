RSpec.describe "Accès de l'usager à la visioconférence de son RDV", type: :request do
  let(:user) { create(:user) }
  let(:motif) { create(:motif, location_type: :visio) }
  let(:starts_at) { Time.zone.now.change(hour: 23, min: 0) }
  let(:rdv) { create(:rdv, motif:, organisation: motif.organisation, lieu: nil, users: [user], visio_url_custom:, starts_at:) }

  before { sign_in user }

  context "quand le lien de visio a été généré" do
    let(:visio_url_custom) { "https://visio.numerique.gouv.fr/salon" }

    it "redirige vers le salon" do
      get visio_users_rdv_path(rdv)

      expect(response).to redirect_to("https://visio.numerique.gouv.fr/salon")
    end

    it "affiche le lien sur la page du RDV le jour du RDV" do
      get users_rdv_path(rdv)

      expect(response.body).to include("rejoindre la visioconférence")
    end

    context "quand le RDV a lieu un jour suivant" do
      let(:starts_at) { 1.day.from_now }

      it "invite l'usager à revenir le jour du RDV" do
        get users_rdv_path(rdv)

        expect(response.body).to include("Le lien de visioconférence sera disponible sur cette page le jour du rendez-vous.")
        expect(response.body).not_to include("rejoindre la visioconférence")
      end
    end
  end

  context "quand le lien de visio n'a pas encore été généré" do
    let(:visio_url_custom) { nil }

    it "invite l'usager à revenir ultérieurement" do
      get visio_users_rdv_path(rdv)

      expect(response).to redirect_to(users_rdv_path(rdv))
      expect(flash[:notice]).to eq("Le lien de visioconférence n’est pas encore disponible : revenez ultérieurement pour l’obtenir.")
    end

    it "affiche le message sur la page du RDV" do
      get users_rdv_path(rdv)

      expect(response.body).to include("Le lien de visioconférence n’est pas encore disponible : revenez ultérieurement pour l’obtenir.")
      expect(response.body).not_to include("rejoindre la visioconférence")
    end
  end
end
