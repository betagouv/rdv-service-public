# TODO: move those tests to fatures tests
RSpec.describe SearchController, type: :controller do
  render_views
  subject { response.body }

  let!(:departement_number) { "75" }
  let!(:city_code) { "75007" }
  let!(:address) { "20 avenue de ségur" }
  let!(:invitation_token) do
    user.assign_rdv_invitation_token
    user.save!
    user.rdv_invitation_token
  end

  let!(:user) { create(:user, organisations: [organisation]) }

  let!(:organisation) { create(:organisation) }
  let!(:other_org) { create(:organisation) }

  let!(:service) { create(:service, name: "Joli service") }
  let(:now) { Date.new(2019, 7, 22) }

  let!(:rsa_orientation) { create(:motif_category, name: "RSA orientation sur site", short_name: "rsa_orientation") }
  let!(:rsa_orientation_on_phone_platform) { create(:motif_category, name: "RSA orientation sur plateforme téléphonique", short_name: "rsa_orientation_on_phone_platform") }

  let!(:motif) { create(:motif, name: "RSA orientation 1", service: service, motif_category: rsa_orientation, organisation: organisation) }
  let!(:motif2) { create(:motif, name: "RSA orientation 2", service: service, motif_category: rsa_orientation_on_phone_platform, organisation: organisation) }
  let!(:motif3) { create(:motif, name: "RSA orientation 3", service: service, organisation: other_org) }
  let!(:motif4) { create(:motif, name: "Motif numéro 4", service: service, organisation: other_org) }

  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, organisation: organisation) }
  let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif2], lieu: lieu2, organisation: organisation) }
  let!(:plage_ouverture3) { create(:plage_ouverture, motifs: [motif3], lieu: lieu, organisation: other_org) }
  let!(:plage_ouverture4) { create(:plage_ouverture, motifs: [motif4], lieu: lieu2, organisation: other_org) }

  let!(:lieu) { create(:lieu, name: "Lieu numéro 1", organisation: organisation) }
  let!(:lieu2) { create(:lieu, name: "Lieu numéro 2", organisation: organisation) }

  let!(:creneaux_search) do
    instance_double(
      CreneauxSearch::ForUser,
      creneaux: [],
      next_availability: build(:creneau, starts_at: Time.zone.parse("2019-08-05 08h00"))
    )
  end
  let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.where(id: [motif.id])) }

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
            organisation_ids: [organisation.id], address: address, departement: departement_number, city_code: city_code,
            invitation_token: invitation_token,
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
            organisation_ids: [organisation.id], address: address, departement: departement_number, city_code: city_code,
            invitation_token: invitation_token,
          }
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to include("L’utilisateur connecté ne correspond pas à l’utilisateur invité. Déconnectez-vous et réessayez.")
        end
      end
    end

    describe "motif selection" do
      let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.where(id: [motif.id, motif2.id])) }

      it "lists the motifs retrieved by the geo search" do
        get :search_rdv, params: {
          address: address, departement: departement_number, city_code: city_code,
        }
        expect(subject).to include("RSA orientation 1")
        expect(subject).to include("RSA orientation 2")
        expect(subject).not_to include("RSA orientation 3")
      end

      context "for an invitation" do
        before do
          request.session["invitation"] = {
            address: address, departement: departement_number, city_code: city_code, invitation_token: invitation_token,
            expires_at: 1.hour.from_now,
          }
        end

        context "when a motif category is passed" do
          it "retrieves motifs from the selected category" do
            get :search_rdv, params: {
              address: address, departement: departement_number, city_code: city_code, motif_category_short_name: "rsa_orientation",
            }
            expect(subject).to include("RSA orientation 1")
            expect(subject).not_to include("RSA orientation 2")
          end
        end

        context "when there are matching motifs for the geo search available_motifs" do
          let(:geo_search) do
            instance_double(Users::GeoSearch, available_motifs: Motif.where(id: [motif2.id]))
          end

          it "lists the available motifs" do
            get :search_rdv
            expect(subject).to include("RSA orientation 2")
            expect(subject).not_to include("RSA orientation 1")
            expect(subject).not_to include("RSA orientation 3")
            expect(subject).not_to include("Motif numéro 4")
          end
        end

        context "when there are no matching motifs for the geo search available_motifs after filtering" do
          it "lists the matching motifs linked to the orgas passed in the url" do
            get :search_rdv, params: {
              organisation_ids: [organisation.id], motif_category_short_name: "rsa_orientation",
            }
            expect(subject).to include("RSA orientation 1")
            expect(subject).not_to include("RSA orientation 2")
            expect(subject).not_to include("RSA orientation 3")
            expect(subject).not_to include("Motif numéro 4")
          end
        end
      end
    end

    describe "lieu selection" do
      before do
        allow(CreneauxSearch::ForUser).to receive(:new).with(
          user: nil,
          motif: motif,
          lieu: lieu,
          date_range: (Date.new(2019, 7, 22)..Date.new(2019, 7, 29)),
          geo_search: geo_search
        ).and_return(creneaux_search)
      end

      it "lists the the available lieux linked to the motifs" do
        get :search_rdv, params: {
          address: address, departement: departement_number, city_code: city_code,
          motif_name_with_location_type: motif.name_with_location_type,
        }
        expect(subject).to include("Lieu numéro 1")
        expect(subject).not_to include("Lieu numéro 2")
      end

      it "shows the next availability" do
        slot = Creneau.new(
          starts_at: Time.zone.parse("20190805 8:00"),
          motif: motif,
          lieu_id: plage_ouverture.lieu_id,
          agent: plage_ouverture.agent
        )
        allow(NextAvailabilityService).to receive(:find).and_return(slot)
        get :search_rdv, params: {
          address: address, departement: departement_number, city_code: city_code,
          motif_name_with_location_type: motif.name_with_location_type,
        }
        expect(subject).to match(/Prochaine disponibilité le(.)*lundi 05 août 2019 à 08h00/)
      end
    end

    describe "creneaux selection" do
      before do
        allow(CreneauxSearch::ForUser).to receive(:new).with(
          user: nil,
          motif: motif,
          lieu: lieu,
          date_range: (Date.new(2019, 7, 22)..Date.new(2019, 7, 28)),
          geo_search: geo_search
        ).and_return(creneaux_search)
      end

      context "creneaux are available soon" do
        let!(:creneaux_search) do
          instance_double(
            CreneauxSearch::ForUser,
            creneaux: [build(:creneau, starts_at: Time.zone.parse("2019-07-22 08h00"))]
          )
        end

        it "returns a creneau" do
          get :search_rdv, params: {
            lieu_id: lieu.id, address: address, departement: departement_number, city_code: city_code,
            motif_name_with_location_type: motif.name_with_location_type,
          }
          expect(subject).to include("08:00")
        end
      end

      context "when first availability is in the future" do
        let!(:creneaux_search) do
          instance_double(
            CreneauxSearch::ForUser,
            creneaux: [],
            next_availability: build(:creneau, starts_at: Time.zone.parse("2019-08-05 08h00"))
          )
        end

        it "returns next availability" do
          get :search_rdv, params: {
            lieu_id: lieu.id, address: address, departement: departement_number, city_code: city_code,
            motif_name_with_location_type: motif.name_with_location_type,
          }
          expect(subject).to match(/Prochaine disponibilité le(.)*lundi 05 août 2019 à 08h00/)
        end
      end
    end
  end

  describe "#publick_link_to_creneaux" do
    let(:params) { { starts_at: Time.zone.now, lieu_id: lieu.id, motif_id: motif.id } }

    it "redirects to /prendre_rdv with the proper params" do
      get :public_link_to_creneaux, params: params

      expect(response).to redirect_to(new_users_rdv_wizard_step_path(
                                        starts_at: params[:starts_at],
                                        lieu_id: params[:lieu_id],
                                        departement: organisation.departement_number,
                                        motif_name_with_location_type: motif.name_with_location_type,
                                        motif_id: motif.id
                                      ))
    end
  end
end
