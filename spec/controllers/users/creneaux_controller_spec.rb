RSpec.describe Users::CreneauxController, type: :controller do
  render_views

  describe "GET #edit" do
    let(:now) { "01/01/2019 10:00".to_datetime }
    let!(:lieu) { create(:lieu, address: "10 rue de la Ferronerie 44100 Nantes") }
    let(:rdv) { create(:rdv, starts_at: 5.days.from_now, location: "10 rue de la Ferronerie 44100 Nantes") }
    let!(:user) { create(:user) }

    subject do
      get :edit, params: { rdv_id: rdv.id, starts_at: 3.day.from_now }
      rdv.reload
    end

    before do
      travel_to(now)
      sign_in user
    end

    context "creneau is available" do
      let!(:plage_ouverture) { create(:plage_ouverture, first_day: now + 3.days, start_time: Tod::TimeOfDay.new(10)) }

      before { subject }

      it { expect(assigns(:creneau_available)).to eq(true) }
      it { expect(response.body).to include("Un créneau s'est libéré") }
      it { expect(response.body).to include("Changer de créneau") }
    end

    context "creneau isn't available" do
      before { subject }

      it { expect(assigns(:creneau_available)).to eq(false) }
      it { expect(response.body).to include("Ce créneau n'est plus disponible") }
      it { expect(response.body).to include(rdv.motif.name) }
    end
  end

  describe "PUT #update" do
    let(:now) { "01/01/2019 10:00".to_datetime }
    let!(:lieu) { create(:lieu, address: "10 rue de la Ferronerie 44100 Nantes") }
    let(:rdv) { create(:rdv, starts_at: 5.days.from_now, location: "10 rue de la Ferronerie 44100 Nantes") }
    let!(:user) { create(:user) }

    subject do
      put :update, params: { rdv_id: rdv.id, starts_at: 3.day.from_now }
      rdv.reload
    end

    before do
      travel_to(now)
      sign_in user
    end

    context "creneau is available" do
      let!(:plage_ouverture) { create(:plage_ouverture, first_day: now + 3.days, start_time: Tod::TimeOfDay.new(10)) }
      let!(:starts_at) { 3.day.from_now }

      before { subject }

      it { expect(assigns(:creneau_available)).to eq(nil) }
      it { expect(response.body).to include("Votre RDV a été modifié") }
      it { expect(rdv.starts_at).to eq(starts_at) }
    end

    context "creneau isn't available" do
      let!(:starts_at) { 3.day.from_now }

      it { expect(subject).to redirect_to(edit_users_creneaux_url(rdv_id: rdv.id, starts_at: starts_at.to_s)) }
    end
  end
end
