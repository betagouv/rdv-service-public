RSpec.describe Rdv::VisioConcern, type: :concern do
  describe "#visio_url" do
    it "retourne l'URL custom pour un motif en visio" do
      rdv = build(:rdv, motif: build(:motif, location_type: :visio), visio_url_custom: "https://visio.numerique.gouv.fr/salon")

      expect(rdv.visio_url).to eq("https://visio.numerique.gouv.fr/salon")
    end

    it "ne retourne plus de lien Webconf quand il n'y a pas d'URL custom" do
      rdv = build(:rdv, motif: build(:motif, location_type: :visio), visio_url_custom: nil)

      expect(rdv.visio_url).to be_nil
    end

    it "ne retourne rien pour un motif qui n'est pas en visio" do
      rdv = build(:rdv, visio_url_custom: "https://visio.numerique.gouv.fr/salon")

      expect(rdv.visio_url).to be_nil
    end
  end

  describe "création du salon à la création du RDV" do
    let(:organisation) { create(:organisation) }
    let(:visio_motif) { create(:motif, organisation:, location_type: :visio) }
    let(:agent_with_token) do
      create(:agent, basic_role_in_organisations: [organisation], menshen_access_token: "un-jeton-menshen", menshen_access_token_expires_at: 1.hour.from_now)
    end

    it "programme la création du salon si un des agents a un jeton Menshen valide" do
      expect do
        create(:rdv, organisation:, motif: visio_motif, lieu: nil, agents: [create(:agent, basic_role_in_organisations: [organisation]), agent_with_token])
      end.to have_enqueued_job(Rdvs::CreateVisioRoomJob)
    end

    it "ne programme rien si aucun agent n'a de jeton Menshen valide" do
      expect do
        create(:rdv, organisation:, motif: visio_motif, lieu: nil, agents: [create(:agent, basic_role_in_organisations: [organisation])])
      end.not_to have_enqueued_job(Rdvs::CreateVisioRoomJob)
    end

    it "ne programme rien si le RDV a déjà un salon ou n'est pas en visio" do
      expect do
        create(:rdv, organisation:, motif: visio_motif, lieu: nil, agents: [agent_with_token], visio_url_custom: "https://visio.numerique.gouv.fr/existant")
        create(:rdv, organisation:, agents: [agent_with_token])
      end.not_to have_enqueued_job(Rdvs::CreateVisioRoomJob)
    end

    it "ne programme rien lors d'une mise à jour du RDV" do
      rdv = create(:rdv, organisation:, motif: visio_motif, lieu: nil)
      rdv.agents << agent_with_token

      expect { rdv.update!(context: "nouveau contexte") }.not_to have_enqueued_job(Rdvs::CreateVisioRoomJob)
    end

    context "quand la Visio est désactivée" do
      stub_env_with(VISIO_NUMERIQUE_DISABLED: "true")

      it "ne programme rien" do
        expect do
          create(:rdv, organisation:, motif: visio_motif, lieu: nil, agents: [agent_with_token])
        end.not_to have_enqueued_job(Rdvs::CreateVisioRoomJob)
      end
    end
  end

  describe "#visio_join_url" do
    it "retourne un lien public avec un token permettant de retrouver le RDV" do
      motif = create(:motif, location_type: :visio)
      rdv = create(:rdv, motif:, organisation: motif.organisation, lieu: nil)

      token = rdv.visio_join_url.split("/v/").last
      expect(rdv.visio_join_url).to start_with("http://www.rdv-solidarites-test.localhost/v/")
      expect(Rdv.find_signed(token, purpose: :visio)).to eq(rdv)
    end
  end

  describe "validation des URL custom" do
    subject { rdv }

    let(:rdv) { build(:rdv, visio_url_custom:) }

    context "nil" do
      let(:visio_url_custom) { nil }

      it { is_expected.to be_valid }
    end

    context "vide" do
      let(:visio_url_custom) { "" }

      it { is_expected.to be_valid }
    end

    context "URL webinaire.numerique.gouv.fr" do
      let(:visio_url_custom) { "https://webinaire.numerique.gouv.fr/test-123" }

      it { is_expected.to be_valid }
    end

    context "URL MS Teams" do
      let(:visio_url_custom) { "https://teams.live.com/meet/93233334488899?p=cUKabcdEFG" }

      it { is_expected.to be_valid }
    end

    context "URL Zoom" do
      let(:visio_url_custom) { "https://us04web.zoom.us/j/6022378945?pwd=dXV12345667" }

      it { is_expected.to be_valid }
    end

    context "mal formée" do
      let(:visio_url_custom) { "hptts://hackeverything" }

      specify do
        expect(rdv).to be_invalid
        expect(rdv.errors[:visio_url_custom].first).to eq("n’est pas une URL valide")
      end
    end

    context "domaine non autorisé" do
      let(:visio_url_custom) { "https://outil-inconnu.fr/test-123" }

      specify do
        expect(rdv).to be_invalid
        expect(rdv.errors[:visio_url_custom].first).to match(/doit provenir d’un des domaines suivants/)
      end
    end
  end
end
