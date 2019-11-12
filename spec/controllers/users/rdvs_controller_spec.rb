RSpec.describe Users::RdvsController, type: :controller do
  describe "POST create" do
    let(:user) { create(:user) }
    let(:motif) { create(:motif) }
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], first_day: Date.new(2019, 7, 24)) }

    subject { post :create, params: { organisation_id: plage_ouverture.organisation_id, rdv: { motif_id: motif.id, lieu_id: plage_ouverture.lieu.id, starts_at: starts_at, departement: "12", where: "1 rue de la, ville 12345" } } }

    before do
      travel_to(Time.zone.local(2019, 7, 20))
      sign_in user
      subject
    end

    after { travel_back }

    describe "when the starts_at is correct" do
      let(:starts_at) { Time.zone.local(2019, 7, 25, 10, 30) }

      it "creates rdv" do
        expect(Rdv.count).to eq(1)
        expect(response).to redirect_to users_rdv_confirmation_path(Rdv.last.id)
      end
    end

    describe "when the starts_at not correct" do
      let(:starts_at) { Time.zone.local(2019, 7, 25, 14, 30) }

      it "creates rdv" do
        expect(Rdv.count).to eq(0)
        expect(response).to redirect_to redirect_to welcome_motif_path("12", motif.name, where: "1 rue de la, ville 12345")
        expect(flash[:error]).to eq "Ce creneau n'est plus disponible. Veuillez en sélectionner un autre."
      end
    end
  end
end
