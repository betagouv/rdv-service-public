# frozen_string_literal: true

RSpec.describe ExternalInvitations::MotifsController, type: :controller do
  render_views

  describe "GET #index" do
    subject { response.body }

    let!(:territory) { create(:territory, departement_number: departement_number) }
    let!(:departement_number) { "72" }
    let!(:city_code) { "72100" }
    let!(:organisation) { create(:organisation, territory: territory) }

    let(:service) { create(:service, name: "Joli service") }
    let!(:another_service) { create(:service) }

    let!(:motif) { create(:motif, name: "Motif numéro 1", service: service, reservable_online: true, organisation: organisation) }
    let!(:motif2) { create(:motif, name: "Motif numéro 2", service: service, reservable_online: true, organisation: organisation) }
    let!(:motif3) { create(:motif, name: "Motif numéro 3", service: service, reservable_online: true, organisation: organisation) }
    let!(:motif4) { create(:motif, name: "Motif numéro 4", service: another_service, reservable_online: true, organisation: organisation) }

    let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], organisation: organisation) }
    let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif2], organisation: organisation) }
    let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.where(id: motif.id)) }

    before do
      allow(Users::GeoSearch).to receive(:new)
        .with(departement: departement_number, city_code: city_code, street_ban_id: nil)
        .and_return(geo_search)
    end

    context "when the geo search retrieves available motifs" do
      it "lists the motifs retrieved by the geo search" do
        get :index, params: {
          organisation_id: organisation.id, service_id: service.id, departement: departement_number, city_code: city_code
        }
        expect(subject).to include("Motif numéro 1")
        expect(subject).not_to include("Motif numéro 2")
      end
    end

    context "when the geo search does not retrieve available motifs" do
      let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.none) }

      it "lists all the organisation motifs linked to the service available for reservation" do
        get :index, params: {
          organisation_id: organisation.id, service_id: service.id, departement: departement_number, city_code: city_code
        }
        expect(subject).to include("Motif numéro 1")
        expect(subject).to include("Motif numéro 2")
        expect(subject).not_to include("Motif numéro 3")
        expect(subject).not_to include("Motif numéro 4")
      end

      context "when no motifs are available for reservation" do
        it "reveals a problem" do
          get :index, params: {
            organisation_id: organisation.id, service_id: another_service.id, departement: departement_number, city_code: city_code
          }
          expect(subject).to include("Nous sommes désolés, un problème semble s'être produit pour votre invitation.")
          expect(subject).to include("data.insertion@beta.gouv.fr")
        end
      end
    end
  end
end
