RSpec.describe Users::RdvsController, type: :controller do
  render_views

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
        expect(user.rdvs.last.created_by_user?).to be(true)
      end
    end

    describe "when the starts_at not correct" do
      let(:starts_at) { Time.zone.local(2019, 7, 25, 14, 30) }

      it "creates rdv" do
        expect(Rdv.count).to eq(0)
        expect(response).to redirect_to lieux_path(search: { departement: "12", service: motif.service_id, motif: motif.name, where: "1 rue de la, ville 12345" })
        expect(flash[:error]).to eq "Ce creneau n'est plus disponible. Veuillez en sélectionner un autre."
      end
    end
  end

  describe "PUT #cancel" do
    let(:now) { "01/01/2019 14:20".to_datetime }
    let(:rdv) { create(:rdv, starts_at: 5.hours.from_now) }
    let!(:user) { create(:user) }

    subject do
      put :cancel, params: { rdv_id: rdv.id }
      rdv.reload
    end

    before do
      travel_to(now)
      sign_in signed_in_user
    end

    context 'when user belongs to rdv' do
      let(:signed_in_user) { rdv.users.first }

      it { expect { subject }.to change(rdv, :cancelled_at).from(nil).to(now) }

      it "redirects to rdvs" do
        subject
        expect(response).to redirect_to users_rdvs_path
      end

      context "when rdv is not cancellable" do
        let(:rdv) { create(:rdv, starts_at: 3.hours.from_now) }

        it { expect { subject }.not_to change(rdv, :cancelled_at) }
      end
    end

    context "when user does not belongs to rdv" do
      let(:signed_in_user) { create(:user) }

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end

  describe "GET #change_creneau" do
    let(:now) { "01/01/2019 10:00".to_datetime }
    let!(:lieu) { create(:lieu, address: "10 rue de la Ferronerie 44100 Nantes") }
    let(:rdv) { create(:rdv, starts_at: 5.days.from_now, location: "10 rue de la Ferronerie 44100 Nantes") }
    let!(:user) { create(:user) }

    subject do
      get :change_creneau, params: { rdv_id: rdv.id, starts_at: 3.day.from_now }
      rdv.reload
    end

    before do
      travel_to(now)
      sign_in user
    end

    context "creneau is available" do
      let!(:plage_ouverture) { create(:plage_ouverture, first_day: now + 3.days, start_time: Tod::TimeOfDay.new(10)) }

      before { subject }

      it { expect(assigns(:state)).to eq(true) }
      it { expect(response.body).to include("Un créneau s'est libéré") }
      it { expect(response.body).to include("Changer de créneau") }
    end

    context "creneau isn't available" do
      before { subject }

      it { expect(assigns(:state)).to eq(false) }
      it { expect(response.body).to include("Créneau indisponible") }
      it { expect(response.body).to include(rdv.motif.name) }
    end

    context "rdv was updated" do
      let!(:starts_at) { 3.day.from_now }

      subject do
        get :change_creneau, params: { rdv_id: rdv.id, starts_at: starts_at, confirmed: 'true' }
        rdv.reload
      end

      before { subject }

      it { expect(assigns(:state)).to eq(nil) }
      it { expect(response.body).to include("Votre RDV a bien été modifié") }
      it { expect(rdv.starts_at).to eq(starts_at) }
    end
  end
end
