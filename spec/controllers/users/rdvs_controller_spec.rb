RSpec.describe Users::RdvsController, type: :controller do
  render_views

  describe "POST create" do
    subject do
      post :create, params: { organisation_id: organisation.id, lieu_id: lieu.id, departement: "12", city_code: "12100", where: "1 rue de la, ville 12345", motif_id: motif.id, starts_at: starts_at }
    end

    let!(:organisation) { create(:organisation) }
    let(:user) { create(:user) }
    let(:motif) { create(:motif, organisation: organisation) }
    let(:lieu) { create(:lieu, organisation: organisation) }
    let(:starts_at) { DateTime.parse("2020-10-20 10h30") }
    let(:mock_geo_search) { instance_double(Users::GeoSearch) }

    before do
      travel_to(Time.zone.local(2019, 7, 20))
      sign_in user
      expect(Users::GeoSearch).to receive(:new)
        .with(departement: "12", city_code: "12100")
        .and_return(mock_geo_search)
      expect(Users::CreneauSearch).to receive(:creneau_for)
        .with(user: user, starts_at: starts_at, motif: motif, lieu: lieu, geo_search: mock_geo_search)
        .and_return(mock_creneau)
      subject
    end

    after { travel_back }

    describe "when there is an available creneau" do
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let(:mock_creneau) do
        instance_double(Creneau, agent: agent, motif: motif, lieu: lieu, starts_at: starts_at, duration_in_min: 30)
      end

      it "creates rdv" do
        expect(Rdv.count).to eq(1)
        expect(response).to redirect_to users_rdvs_path
        expect(user.rdvs.last.created_by_user?).to be(true)
      end
    end

    describe "when there is no available creneau" do
      let(:mock_creneau) { nil }

      it "creates rdv" do
        expect(Rdv.count).to eq(0)
        expect(response).to redirect_to lieux_path(search: { departement: "12", service: motif.service_id, motif_name_with_location_type: motif.name_with_location_type,
                                                             where: "1 rue de la, ville 12345" })
        expect(flash[:error]).to eq "Ce creneau n'est plus disponible. Veuillez en sélectionner un autre."
      end
    end
  end

  describe "PUT #cancel" do
    context "when user belongs to rdv" do
      it "change cancelled_at" do
        rdv = create(:rdv, starts_at: 5.hours.from_now)
        now = "01/01/2019 14:20".to_datetime

        travel_to(now)
        sign_in rdv.users.first

        put :cancel, params: { rdv_id: rdv.id }
        expect(rdv.reload.cancelled_at).to be_within(5.seconds).of(now)
      end

      it "call RdvUpdate.update function" do
        rdv = create(:rdv, starts_at: 5.hours.from_now)
        sign_in rdv.users.first
        expect(RdvUpdater).to receive(:update_by_user).with(rdv, { status: "excused" })
        put :cancel, params: { rdv_id: rdv.id }
      end

      it "redirects to rdvs" do
        rdv = create(:rdv, starts_at: 5.hours.from_now)
        sign_in rdv.users.first
        put :cancel, params: { rdv_id: rdv.id }
        expect(response).to redirect_to users_rdvs_path
      end

      it "when rdv is not cancellable" do
        rdv = create(:rdv, starts_at: 3.hours.from_now)
        sign_in rdv.users.first
        expect do
          put :cancel, params: { rdv_id: rdv.id }
        end.not_to change(rdv, :cancelled_at)
      end
    end

    it "when user does not belongs to rdv" do
      rdv = create(:rdv, starts_at: 5.hours.from_now)
      other_user = create(:user)

      sign_in other_user

      expect do
        put :cancel, params: { rdv_id: rdv.id }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
