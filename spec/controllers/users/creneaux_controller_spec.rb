RSpec.describe Users::CreneauxController, type: :controller do
  render_views

  describe "GET #new" do
    let(:now) { "01/01/2019 10:00".to_datetime }
    let!(:lieu) { create(:lieu, address: "10 rue de la Ferronerie 44100 Nantes") }
    let(:rdv) { create(:rdv, starts_at: 5.days.from_now, location: "10 rue de la Ferronerie 44100 Nantes") }
    let!(:user) { create(:user) }

    subject do
      get :new, params: { rdv_id: rdv.id, starts_at: 3.day.from_now }
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
      it { expect(response.body).to include("Créneau indisponible") }
      it { expect(response.body).to include(rdv.motif.name) }
    end

    context "rdv was updated" do
      let!(:starts_at) { 3.day.from_now }

      subject do
        get :new, params: { rdv_id: rdv.id, starts_at: starts_at, confirmed: 'true' }
        rdv.reload
      end

      before { subject }

      it { expect(assigns(:creneau_available)).to eq(nil) }
      it { expect(response.body).to include("Votre RDV a été modifié") }
      it { expect(rdv.starts_at).to eq(starts_at) }
    end
  end
end
