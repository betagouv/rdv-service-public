# frozen_string_literal: true

RSpec.describe ExternalInvitations::LieuxController, type: :controller do
  render_views
  subject { response.body }

  let!(:departement_number) { "72" }
  let!(:city_code) { "72100" }
  let!(:invitation_token) do
    user.invite! { |u| u.skip_invitation = true }
    user.raw_invitation_token
  end

  let!(:user) { create(:user, organisations: [organisation]) }

  let!(:organisation) { create(:organisation) }

  let!(:service) { create(:service, name: "Joli service") }
  let(:now) { Date.new(2019, 7, 22) }
  let!(:motif) { create(:motif, name: "Motif numéro 1", service: service, reservable_online: true, organisation: organisation) }
  let!(:motif2) { create(:motif, service: service, reservable_online: true, organisation: organisation) }

  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, organisation: organisation) }
  let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif2], lieu: lieu2, organisation: organisation) }

  let!(:lieu) { create(:lieu, name: "Lieu numéro 1") }
  let!(:lieu2) { create(:lieu, name: "Lieu numéro 2") }

  let!(:creneaux_search) do
    instance_double(
      Users::CreneauxSearch,
      creneaux: [],
      next_availability: build(:creneau, starts_at: DateTime.parse("2019-08-05 08h00"))
    )
  end
  let!(:geo_search) { instance_double(Users::GeoSearch) }

  before do
    travel_to(now)
    allow(Users::GeoSearch).to receive(:new)
      .with(departement: "72", city_code: "72100", street_ban_id: nil)
      .and_return(geo_search)
  end

  describe "GET #index" do
    before do
      allow(Users::CreneauxSearch).to receive(:new).with(
        user: nil,
        motif: motif,
        lieu: lieu,
        date_range: (Date.new(2019, 7, 15)..Date.new(2019, 7, 22)),
        geo_search: geo_search
      ).and_return(creneaux_search)
    end

    it "lists the the available lieux linked to the motifs" do
      get :index, params: {
        organisation_id: organisation.id, service_id: service.id, motif_id: motif.id, departement: departement_number, city_code: city_code,
        invitation_token: invitation_token
      }
      expect(subject).to include("Lieu numéro 1")
      expect(subject).not_to include("Lieu numéro 2")
    end

    it "shows the next availability" do
      get :index, params: {
        organisation_id: organisation.id, service_id: service.id, motif_id: motif.id, departement: departement_number, city_code: city_code,
        invitation_token: invitation_token
      }
      expect(subject).to match(/Prochaine disponibilité le(.)*lundi 05 août 2019 à 08h00/)
    end

    context "when no matching motifs is found" do
      let!(:motif) { create(:motif,  service: service, reservable_online: false, organisation: organisation) }

      it "redirects to the motifs list" do
        get :index, params: {
          organisation_id: organisation.id, service_id: service.id, motif_id: motif.id, departement: departement_number,
          city_code: city_code, invitation_token: invitation_token
        }
        expect(response).to redirect_to(
          external_invitations_organisation_service_motifs_path(
            organisation: organisation, service: service, departement: departement_number,
            city_code: city_code, invitation_token: invitation_token
          )
        )
      end
    end
  end

  describe "GET #show" do
    before do
      allow(Users::CreneauxSearch).to receive(:new).with(
        user: nil,
        motif: motif,
        lieu: lieu,
        date_range: (Date.new(2019, 7, 22)..Date.new(2019, 7, 28)),
        geo_search: geo_search
      ).and_return(creneaux_search)
    end

    context "creneaux are available soon" do
      let(:creneaux_search) do
        instance_double(
          Users::CreneauxSearch,
          creneaux: [build(:creneau, starts_at: DateTime.parse("2019-07-22 08h00"))]
        )
      end

      it "returns a creneau" do
        get :show, params: {
          id: lieu.id, organisation_id: organisation.id, service_id: service.id,
          motif_id: motif.id, departement: departement_number, city_code: city_code,
          invitation_token: invitation_token
        }
        expect(subject).to include("08:00")
      end
    end

    context "when first availability is in the future" do
      let(:creneaux_search) do
        instance_double(
          Users::CreneauxSearch,
          creneaux: [],
          next_availability: build(:creneau, starts_at: DateTime.parse("2019-08-05 08h00"))
        )
      end

      it "returns next availability" do
        get :show, params: {
          id: lieu.id, organisation_id: organisation.id, service_id: service.id,
          motif_id: motif.id, departement: departement_number, city_code: city_code, invitation_token: invitation_token
        }
        expect(subject).to match(/Prochaine disponibilité le(.)*lundi 05 août 2019 à 08h00/)
      end
    end
  end
end
