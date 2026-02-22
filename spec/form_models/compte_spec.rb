RSpec.describe Compte do
  context "when the agent already has an account because they logged in with ProConnect" do
    let!(:agent) { create(:agent) }
    let(:super_admin) { create(:super_admin) }
    let(:service) { create(:service) }

    it "creates the organisation and adds the agent" do
      described_class.new(
        {
          territory: {
            name: "Montreuil", departement_number: 93,
          },
          organisation: { name: "Mairie de Montreuil", ants_connectable: false },
          lieu: { address: "1 rue de la république", latitude: 48.859, longitude: 2.347 },
          agent: { first_name: "Francis", last_name: "Factice", email: agent.email, service_ids: [service.id] },
        },
        current_domain: Domain::RDV_SERVICE_PUBLIC
      ).save!

      expect(agent.reload.roles.last).to have_attributes(access_level: "admin")
      expect(agent.organisations.last.name).to eq "Mairie de Montreuil"
    end

    context "when another super admin has already responded to the territory creation request" do
      let(:territory_creation_request) { create(:territory_creation_request, response: :refused) }

      it "raises an error" do
        compte = described_class.new(
          {
            territory: {
              name: "Montreuil", departement_number: 93,
            },
            organisation: { name: "Mairie de Montreuil", ants_connectable: false },
            lieu: { address: "1 rue de la république", latitude: 48.859, longitude: 2.347 },
            agent: { first_name: "Francis", last_name: "Factice", email: agent.email, service_ids: [service.id] },
          },
          current_domain: Domain::RDV_SERVICE_PUBLIC,
          territory_creation_request:
        )

        expect { compte.save! }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Territory.where(name: "Montreuil")).not_to exist
        expect(territory_creation_request.reload.response).to eq "refused"
      end
    end
  end
end
