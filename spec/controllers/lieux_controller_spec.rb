RSpec.describe LieuxController, type: :controller do
  render_views

  let(:lieu) { create(:lieu, latitude: 50.63, longitude: 3.06) }
  let(:lieu2) { create(:lieu, latitude: 50.72, longitude: 3.16) }
  let(:motif) { create(:motif, online: true) }
  let(:now) { Date.new(2019, 7, 22) }
  let!(:plage_ouverture) { create(:plage_ouverture, :weekly, title: "Tous les lundis", first_day: first_day, lieu: lieu, motifs: [motif]) }
  let!(:plage_ouverture2) { create(:plage_ouverture, :weekly, title: "Tous les lundis", first_day: first_day + 1.week, lieu: lieu2, motifs: [motif]) }

  before { travel_to(now) }
  after { travel_back }

  describe "GET #show" do
    let(:first_day) { now }

    context "pour un motif" do
      subject { get :show, params: { id: lieu, search: { departement: lieu.organisation.departement, where: "useless 12345", service: motif.service_id, motif_name: motif.name } } }

      before { subject }

      it "returns a success response" do
        expect(response).to be_successful
      end

      it "returns a creneau" do
        expect(response.body).to include("08:00")
      end

      context "when first_day is in the future" do
        let(:first_day) { now + 10.days }

        it "returns a success response" do
          expect(response).to be_successful
        end

        it "returns next availability" do
          expect(response.body).to match(/Prochaine disponibilité le(.)*lundi 05 août 2019 à 08h00/)
        end
      end
    end

    context "pour un rendez-vous de suivi" do
      context "avec un usager non connecté" do
        it "redirige vers la page de login" do
          lieu = create(:lieu, latitude: 50.63, longitude: 3.06)
          motif = create(:motif, online: true, follow_up: true)
          create(:plage_ouverture, :weekly,
                 title: "Tous les lundis",
                 first_day: first_day,
                 lieu: lieu,
                 motifs: [motif])

          get :show, params: {
            id: lieu,
            search: {
              departement: lieu.organisation.departement,
              where: "useless 12345",
              service: motif.service_id,
              motif_name: motif.name,
            },
          }

          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:justification]).to eq("le RDV '#{motif.name}' est disponible pour les personnes déjà suivies. Veuillez vous connecter pour prendre ce type de RDV.")
        end
      end

      context "avec un usager déjà connecté" do
        it "propose les créneaux" do
          usager = create(:user)
          sign_in usager
          lieu = create(:lieu, latitude: 50.63, longitude: 3.06)
          motif = create(:motif, online: true, follow_up: true)
          create(:plage_ouverture, :weekly,
                 title: "Tous les lundis",
                 first_day: first_day,
                 lieu: lieu,
                 motifs: [motif])

          get :show, params: {
            id: lieu,
            search: {
              departement: lieu.organisation.departement,
              where: "useless 12345",
              service: motif.service_id,
              motif_name: motif.name,
            },
          }

          expect(response).to be_successful
          expect(flash[:justification]).to be_nil
        end
      end
    end
  end

  describe "GET #index" do
    let(:first_day) { now }
    subject { get :index, params: { search: { departement: lieu.organisation.departement, where: "useless 12345", service: motif.service_id, motif_name: motif.name, latitude: lieu.latitude, longitude: lieu.longitude } } }

    before { subject }

    it "returns a success response" do
      expect(response).to be_successful
    end

    it "returns 2 lieux" do
      expect(response.body).to match(/#{lieu.name}(.)*Prochaine disponibilité le(.)*lundi 22 juillet 2019 à 08h00/)
      expect(response.body).to match(/#{lieu2.name}(.)*Prochaine disponibilité le(.)*lundi 29 juillet 2019 à 08h00/)
    end

    it "returns lieu first" do
      expect(assigns(:lieux).first).to eq(lieu)
    end

    context "request is closer to lieu_2" do
      subject { get :index, params: { search: { departement: lieu.organisation.departement, where: "useless 12345", service: motif.service_id, motif_name: motif.name, latitude: lieu2.latitude, longitude: lieu2.longitude } } }

      it "return lieu2 first" do
        expect(assigns(:lieux).first).to eq(lieu2)
      end
    end
  end
end
