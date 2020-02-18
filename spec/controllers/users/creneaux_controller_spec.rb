RSpec.describe Users::CreneauxController, type: :controller do
  render_views
  let(:now) { "01/01/2019 10:00".to_datetime }
  let!(:lieu) { create(:lieu, address: "10 rue de la Ferronerie 44100 Nantes") }
  let(:rdv) { create(:rdv, starts_at: 5.days.from_now, location: "10 rue de la Ferronerie 44100 Nantes") }
  let!(:user) { create(:user) }

  describe "GET #index" do
    subject do
      get :index, params: { rdv_id: rdv.id }
      rdv.reload
    end

    before do
      travel_to(now)
      sign_in user
    end

    context "no creneaux available" do
      before { subject }

      it { expect(assigns(:all_creneaux)).to be_empty }
      it { expect(response.body).to include("Malheureusement, tous les créneaux sont pris.") }
    end

    context "creneaux available" do
      let!(:plage_ouverture) { create(:plage_ouverture, first_day: now + 3.days, start_time: Tod::TimeOfDay.new(10)) }

      before { subject }

      it { expect(response.body).to include("Voici les créneaux disponibles pour avancer votre rendez-vous.") }
      it { expect(assigns(:date_range)).to eq(3.days.from_now.to_date..3.days.from_now.to_date) }
      it { expect(assigns(:creneaux)).not_to be_empty }
    end
  end

  describe "GET #edit" do
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

      it { expect(response.body).to include("Modification du Rendez-vous") }
      it { expect(response.body).to include("Confirmer le nouveau créneau") }
    end

    context "creneau isn't available" do
      before { subject }

      it { expect(response).to redirect_to(users_creneaux_index_path(rdv_id: rdv.id)) }
    end
  end

  describe "PUT #update" do
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

      it { expect(response.body).to include("Votre RDV a été modifié") }
      it { expect(rdv.starts_at).to eq(starts_at) }
    end

    context "creneau isn't available" do
      let!(:starts_at) { 3.day.from_now }

      it { expect(subject).to redirect_to(users_creneaux_index_path(rdv_id: rdv.id)) }
    end
  end
end
