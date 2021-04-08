RSpec.describe Users::CreneauxController, type: :controller do
  render_views
  let(:organisation) { create(:organisation) }
  let(:now) { "01/01/2019 10:00".to_datetime }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:lieu) { create(:lieu, address: "10 rue de la Ferronerie 44100 Nantes", organisation: organisation) }
  let!(:motif) { create(:motif, organisation: organisation) }
  let!(:user) { create(:user) }
  let(:rdv) { create(:rdv, users: [user], starts_at: 5.days.from_now, lieu: lieu, motif: motif, organisation: organisation) }

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
      let!(:plage_ouverture) { create(:plage_ouverture, first_day: now + 3.days, start_time: Tod::TimeOfDay.new(10), lieu: lieu, agent: agent, motifs: [motif], organisation: organisation) }

      before { subject }

      it { expect(response.body).to include("Voici les créneaux disponibles pour avancer votre rendez-vous du") }
      it { expect(response.body).to include(I18n.l(rdv.starts_at, format: :human).to_s) }
      it { expect(assigns(:date_range)).to eq(3.days.from_now.to_date..3.days.from_now.to_date) }
      it { expect(assigns(:creneaux)).not_to be_empty }
    end
  end

  describe "GET #edit" do
    subject do
      get :edit, params: { rdv_id: rdv.id, starts_at: starts_at }
      rdv.reload
    end

    let(:starts_at) { 3.days.from_now }

    before do
      travel_to(now)
      sign_in user
      expect(Users::CreneauSearch).to receive(:creneau_for)
        .with(user: user, starts_at: starts_at, motif: motif, lieu: lieu)
        .and_return(returned_creneau)
    end

    context "creneau is available" do
      let(:returned_creneau) { Creneau.new }

      before { subject }

      it { expect(response.body).to include("Modification du Rendez-vous") }
      it { expect(response.body).to include("Confirmer le nouveau créneau") }
    end

    context "creneau isn't available" do
      let(:returned_creneau) { nil }

      before { subject }

      it { expect(response).to redirect_to(users_creneaux_index_path(rdv_id: rdv.id)) }
    end
  end

  describe "PUT #update" do
    subject do
      put :update, params: { rdv_id: rdv.id, starts_at: starts_at }
      rdv.reload
    end

    let(:starts_at) { 3.days.from_now }

    before do
      travel_to(now)
      sign_in user
      expect(Users::CreneauSearch).to receive(:creneau_for)
        .with(user: user, starts_at: starts_at, motif: motif, lieu: lieu)
        .and_return(returned_creneau)
    end

    context "creneau is available" do
      let(:returned_creneau) { Creneau.new(starts_at: starts_at) }

      before { subject }

      it { expect(response.body).to include("Votre RDV a été modifié") }
      it { expect(rdv.starts_at).to eq(starts_at) }
      it { expect(rdv.created_by).to eq("file_attente") }
    end

    context "creneau isn't available" do
      let(:returned_creneau) { nil }

      it { expect(subject).to redirect_to(users_creneaux_index_path(rdv_id: rdv.id)) }
    end
  end
end
