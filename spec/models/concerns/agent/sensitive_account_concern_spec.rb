RSpec.describe Agent::SensitiveAccountConcern, type: :concern do
  describe "#sensitive_account?" do
    it "retourne la valeur cachée" do
      agent = create(:agent, sensitive_account: true)
      expect(agent.sensitive_account?).to be true
    end
  end

  describe "#compute_sensitive_account" do
    context "quand l'agent est admin d'un territoire avec beaucoup de RDVs" do
      it "retourne true" do
        territory = create(:territory)
        organisation = create(:organisation, territory: territory)
        agent = create(:agent, role_in_territories: [territory])

        # Stub le seuil pour éviter de créer 10001 RDVs
        stub_const("Agent::SensitiveAccountConcern::SENSITIVE_TERRITORY_RDV_THRESHOLD", 2)
        create_list(:rdv, 3, organisation: organisation)

        expect(agent.compute_sensitive_account).to be true
      end
    end

    context "quand l'agent est admin d'un territoire avec peu de RDVs" do
      it "retourne false" do
        territory = create(:territory)
        organisation = create(:organisation, territory: territory)
        agent = create(:agent, role_in_territories: [territory])
        create(:rdv, organisation: organisation)

        expect(agent.compute_sensitive_account).to be false
      end
    end

    context "quand l'agent n'est pas admin territorial" do
      it "retourne false" do
        agent = create(:agent)

        expect(agent.compute_sensitive_account).to be false
      end
    end

    context "quand l'agent est admin de plusieurs territoires dont un avec beaucoup de RDVs" do
      it "retourne true" do
        territory1 = create(:territory)
        territory2 = create(:territory)
        organisation1 = create(:organisation, territory: territory1)
        organisation2 = create(:organisation, territory: territory2)
        agent = create(:agent, role_in_territories: [territory1, territory2])

        # Stub le seuil pour éviter de créer beaucoup de RDVs
        stub_const("Agent::SensitiveAccountConcern::SENSITIVE_TERRITORY_RDV_THRESHOLD", 2)
        create(:rdv, organisation: organisation1)
        create_list(:rdv, 3, organisation: organisation2)

        expect(agent.compute_sensitive_account).to be true
      end
    end
  end

  describe "#refresh_sensitive_account!" do
    it "met à jour la colonne sensitive_account" do
      agent = create(:agent, sensitive_account: false)
      allow(agent).to receive(:compute_sensitive_account).and_return(true)

      agent.refresh_sensitive_account!

      expect(agent.reload.sensitive_account).to be true
    end
  end
end
