RSpec.describe Users::ParticipationsController, type: :controller do
  let!(:rdv) { create(:rdv, :collectif, max_participants_count: max_participants_count) }
  let(:user) { create(:user) }
  let(:max_participants_count) { 2 }

  before do
    sign_in user
  end

  describe "POST #create" do
    context "quand l’usager ne participe pas déjà" do
      it "crée une nouvelle participation" do
        expect { post :create, params: { rdv_id: rdv.id, user_id: user.id } }.to change(Participation, :count).by(1)
      end

      it "informe l’usager que sa participation est confirmée" do
        post :create, params: { rdv_id: rdv.id, user_id: user.id }
        expect(flash[:success]).to eq("Participation confirmée")
      end
    end

    context "quand l'usager participe déjà" do
      before do
        create(:participation, rdv: rdv, user: user)
      end

      it "ne crée pas de nouvelle participation" do
        expect { post :create, params: { rdv_id: rdv.id, user_id: user.id } }.not_to change(Participation, :count)
      end

      it "redirige vers le RDV avec une alerte" do
        post :create, params: { rdv_id: rdv.id, user_id: user.id }
        expect(flash[:notice]).to eq("Usager déjà inscrit")
        expect(response).to redirect_to(users_rdv_path(rdv))
      end
    end

    context "quand il n’y a plus de places disponibles" do
      let(:max_participants_count) { 1 }

      it "ne crée pas de nouvelle participation" do
        expect { post :create, params: { rdv_id: rdv.id, user_id: user.id } }.not_to change(Participation, :count)
      end

      it "alerte l’usager que le créneau n’est plus disponible" do
        post :create, params: { rdv_id: rdv.id, user_id: user.id }
        expect(flash[:alert]).to eq("Ce créneau n'est plus disponible. Veuillez en sélectionner un autre.")
      end

      it "redirige vers la page de prise de rendez-vous" do
        post :create, params: { rdv_id: rdv.id, user_id: user.id }
        expect(response)
          .to redirect_to(prendre_rdv_path(motif_name_with_location_type: rdv.motif.name_with_location_type, lieu_id: rdv.lieu.id, departement: rdv.organisation.territory.departement_number))
      end
    end
  end
end
