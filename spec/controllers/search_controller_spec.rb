# frozen_string_literal: true

RSpec.describe SearchController, type: :controller do
  render_views
  subject { response.body }

  let!(:departement_number) { "75" }
  let!(:city_code) { "75007" }
  let!(:address) { "20 avenue de ségur" }
  let!(:invitation_token) do
    user.invite! { |u| u.skip_invitation = true }
    user.raw_invitation_token
  end

  let!(:user) { create(:user, organisations: [organisation]) }

  let!(:organisation) { create(:organisation) }

  let!(:service) { create(:service, name: "Joli service") }
  let(:now) { Date.new(2019, 7, 22) }
  let!(:motif) { create(:motif, name: "Motif numéro 1", service: service, reservable_online: true, organisation: organisation) }
  let!(:motif2) { create(:motif, name: "Motif numéro 2", service: service, reservable_online: true, organisation: organisation) }

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
  let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.where(id: motif.id)) }

  before do
    travel_to(now)
    allow(Users::GeoSearch).to receive(:new)
      .with(departement: departement_number, city_code: city_code, street_ban_id: nil)
      .and_return(geo_search)
  end

  describe "#search_rdv" do
    context "invitation validation" do
      context "when the token is invalid" do
        let!(:invitation_token) { "random_token" }

        it "redirects with an error message" do
          get :search_rdv, params: {
            organisation_id: organisation.id, service_id: service.id, address: address, departement: departement_number, city_code: city_code,
            invitation_token: invitation_token
          }
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to include("Votre invitation n'est pas valide.")
        end
      end

      context "when a the logged in user is not the invited user" do
        let!(:another_user) { create(:user) }

        before do
          sign_in another_user
        end

        it "redirects with an error message" do
          get :search_rdv, params: {
            organisation_id: organisation.id, service_id: service.id, address: address, departement: departement_number, city_code: city_code,
            invitation_token: invitation_token
          }
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to include("L’utilisateur connecté ne correspond pas à l’utilisateur invité. Déconnectez-vous et réessayez.")
        end
      end

      context "when the user does not belong to the org" do
        let!(:user) { create(:user, organisations: []) }

        it "redirects with an error message" do
          get :search_rdv, params: {
            organisation_id: organisation.id, service_id: service.id, address: address, departement: departement_number, city_code: city_code,
            invitation_token: invitation_token
          }
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to include("L’utilisateur concerné n’appartient pas à cette organisation.")
        end
      end
    end

    describe "motif selection" do
      it "lists the motifs retrieved by the geo search" do
        get :search_rdv, params: {
          organisation_id: organisation.id, address: address, departement: departement_number, city_code: city_code
        }
        expect(subject).to include("Motif numéro 1")
        expect(subject).not_to include("Motif numéro 2")
      end

      context "for an invitation" do
        let!(:another_service) { create(:service) }
        let!(:motif3) { create(:motif, name: "Motif numéro 3", service: service, reservable_online: true, organisation: organisation) }
        let!(:motif4) { create(:motif, name: "Motif numéro 4", service: another_service, reservable_online: true, organisation: organisation) }

        context "when the geo search does not retrieve available motifs" do
          let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.none) }

          it "lists all the organisation motifs linked to the service available for reservation" do
            get :search_rdv, params: {
              organisation_id: organisation.id, service_id: service.id, address: address, departement: departement_number, city_code: city_code,
              invitation_token: invitation_token
            }
            expect(subject).to include("Motif numéro 1")
            expect(subject).to include("Motif numéro 2")
            expect(subject).not_to include("Motif numéro 3")
            expect(subject).not_to include("Motif numéro 4")
          end
        end

        context "when no motifs are available for reservation" do
          it "reveals a problem" do
            get :search_rdv, params: {
              organisation_id: organisation.id, service_id: another_service.id, address: address, departement: departement_number, city_code: city_code,
              invitation_token: invitation_token
            }
            expect(subject).to include("Nous sommes désolés, un problème semble s'être produit pour votre invitation.")
            expect(subject).to include("contact@rdv-solidarites.fr")
          end
        end
      end
    end

    describe "lieu selection" do
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
        get :search_rdv, params: {
          address: address, motif_id: motif.id,
          departement: departement_number, city_code: city_code
        }
        expect(subject).to include("Lieu numéro 1")
        expect(subject).not_to include("Lieu numéro 2")
      end

      it "shows the next availability" do
        get :search_rdv, params: {
          address: address, motif_id: motif.id, departement: departement_number, city_code: city_code
        }
        expect(subject).to match(/Prochaine disponibilité le(.)*lundi 05 août 2019 à 08h00/)
      end
    end

    describe "creneaux selection" do
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
          get :search_rdv, params: {
            lieu_id: lieu.id, motif_id: motif.id, address: address, departement: departement_number, city_code: city_code
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
          get :search_rdv, params: {
            lieu_id: lieu.id, motif_id: motif.id, address: address, departement: departement_number, city_code: city_code
          }
          expect(subject).to match(/Prochaine disponibilité le(.)*lundi 05 août 2019 à 08h00/)
        end
      end
    end
  end
end
