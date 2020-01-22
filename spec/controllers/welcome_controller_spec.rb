RSpec.describe WelcomeController, type: :controller do
  render_views

  describe "GET #welcome_departement" do
    let(:service) { create(:service, name: "Joli service") }
    let!(:motif) { create(:motif, service: service, online: true) }
    let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif]) }
    let(:departement) { plage_ouverture.organisation.departement }

    subject { get :welcome_departement, params: { departement: departement, where: "Arras" } }

    before { subject }

    it "lists services" do
      expect(response.body).to include(service.name)
    end

    context "when there is no plage_ouverture" do
      let(:departement) { "42" }

      it { expect(response.body).to include("La prise de rendez-vous n'est pas disponible pour ce département.") }
    end
  end
end
