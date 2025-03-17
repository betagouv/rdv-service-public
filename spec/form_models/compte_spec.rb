RSpec.describe Compte do
  context "when the agent already has an account because they logged in with ProConnect" do
    let!(:agent) { create(:agent, :no_services) }
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
        Domain::RDV_MAIRIE
      )

      expect(agent.reload.roles.last).to have_attributes(access_level: :admin)
      expect(agent.organisations.last.name).to eq "Mairie de Montreuil"
    end
  end
end
