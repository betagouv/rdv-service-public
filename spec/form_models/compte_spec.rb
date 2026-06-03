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
        expect(Territory.last).to be_nil
        expect(territory_creation_request.reload.response).to eq "refused"
      end
    end

    context "ANTS connectable est activé" do
      let!(:cni_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME) }
      let!(:passport_category) { create(:motif_category, name: Api::Ants::EditorController::PASSPORT_MOTIF_CATEGORY_NAME) }
      let!(:cni_passport_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_AND_PASSPORT_MOTIF_CATEGORY_NAME) }

      it "attache les catégories de motifs ANTS au territoire créé" do
        described_class.new(
          {
            territory: {
              name: "Montreuil", departement_number: 93,
            },
            organisation: { name: "Mairie de Montreuil", ants_connectable: true },
            lieu: { address: "1 rue de la république", latitude: 48.859, longitude: 2.347 },
            agent: { first_name: "Francis", last_name: "Factice", email: agent.email, service_ids: [service.id] },
          },
          current_domain: Domain::RDV_SERVICE_PUBLIC
        ).save!

        expect(agent.reload.roles.last).to have_attributes(access_level: "admin")
        expect(agent.organisations.last.territory.name).to eq("Montreuil")
        expect(agent.organisations.last.territory.motif_categories).to contain_exactly(cni_category, passport_category, cni_passport_category)
      end
    end
  end
end
