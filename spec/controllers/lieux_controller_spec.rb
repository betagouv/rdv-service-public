RSpec.describe LieuxController, type: :controller do
  render_views

  let(:lieu) { create(:lieu) }
  let(:lieu2) { create(:lieu) }
  let(:motif) { create(:motif, online: true) }
  let(:now) { Date.new(2019, 7, 22) }
  let!(:plage_ouverture) { create(:plage_ouverture, :weekly, title: "Tous les lundis", first_day: first_day, lieu: lieu, motifs: [motif]) }
  let!(:plage_ouverture2) { create(:plage_ouverture, :weekly, title: "Tous les lundis", first_day: first_day + 1.week, lieu: lieu2, motifs: [motif]) }

  before { travel_to(now) }
  after { travel_back }

  describe "GET #show" do
    let(:first_day) { now }
    subject { get :show, params: { id: lieu, search: { departement: lieu.organisation.departement, where: "useless 12345", service: motif.service_id, motif: motif.name } } }

    before { subject }

    it "returns a success response" do
      expect(response).to be_successful
    end

    it "returns a creneau" do
      expect(response.body).to include("08:00")
    end

    context "when first_day is in the future" do
      let(:first_day) { now + 10.days }

      it "returns a success response" do
        expect(response).to be_successful
      end

      it "returns next availability" do
        expect(response.body).to match(/Prochaine disponibilité le(.)*lundi 05 août 2019 à 08h00/)
      end
    end
  end

  describe "GET #index" do
    let(:first_day) { now }
    subject { get :index, params: { search: { departement: lieu.organisation.departement, where: "useless 12345", service: motif.service_id, motif: motif.name } } }

    before { subject }

    it "returns a success response" do
      expect(response).to be_successful
    end

    it "returns 2 lieux" do
      expect(response.body).to match(/#{lieu.name}(.)*Prochaine disponibilité le(.)*lundi 22 juillet 2019 à 08h00/)
      expect(response.body).to match(/#{lieu2.name}(.)*Prochaine disponibilité le(.)*lundi 29 juillet 2019 à 08h00/)
    end
  end
end
