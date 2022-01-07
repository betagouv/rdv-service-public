# frozen_string_literal: true

RSpec.describe WelcomeController, type: :controller do
  render_views

  describe "GET #welcome_departement" do
    subject { response.body }

    let!(:territory) { create(:territory, departement_number: "72") }
    let!(:organisation) { create(:organisation, territory: territory) }
    let(:service) { create(:service, name: "Joli service") }
    let!(:motif) { create(:motif, service: service, reservable_online: true, organisation: organisation) }
    let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], organisation: organisation) }

    context "for the right departement" do
      before { get :welcome_departement, params: { departement: "72", where: "Arras" } }

      it { is_expected.to include(service.name) }
    end

    context "for another departement without POs" do
      before { get :welcome_departement, params: { departement: "42", where: "Arras" } }

      it { is_expected.to include("La prise de rendez-vous n'est pas disponible pour ce département.") }
    end

    context "with an invitation token" do
      it "stores the token in session" do
        get :welcome_departement, params: { departement: "42", where: "Arras", invitation_token: "123456" }
        expect(response).to be_successful
        expect(request.session[:invitation_token]).to eq("123456")
      end
    end
  end

  describe "GET #search" do
    it "redirect vers le welcome_departement" do
      get :search, params: { search: { departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", where: "Paris, 75001, 75, Paris, Île-de-France" } }
      expect(response).to redirect_to(welcome_departement_path(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", where: "Paris, 75001, 75, Paris, Île-de-France"))
    end

    it "redirect vers l'accueil" do
      get :search, params: { search: { city_code: "75056", latitude: "48.859", longitude: "2.347", where: "Paris, 75001, 75, Paris, Île-de-France" } }
      expect(response).to redirect_to(root_path)
    end
  end
end
