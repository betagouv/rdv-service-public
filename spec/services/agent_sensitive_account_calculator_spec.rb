RSpec.describe AgentSensitiveAccountCalculator do
  before do
    stub_const("AgentSensitiveAccountCalculator::SENSITIVE_RDV_THRESHOLD", 2)
  end

  describe ".sensitive?" do
    it "est vrai pour un agent admin d'une organisation avec beaucoup de RDVs" do
      organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation])
      create_list(:rdv, 3, organisation: organisation)

      expect(described_class.sensitive?(agent)).to be true
    end

    it "est faux pour un agent basic d'une organisation avec beaucoup de RDVs" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      create_list(:rdv, 3, organisation: organisation)

      expect(described_class.sensitive?(agent)).to be false
    end

    it "ne tient pas compte du volume de RDVs d'une autre organisation" do
      organisation = create(:organisation)
      other_organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation])
      create(:agent, admin_role_in_organisations: [other_organisation])
      create_list(:rdv, 3, organisation: other_organisation)

      expect(described_class.sensitive?(agent)).to be false
    end

    it "tient compte du volume de RDVs de l'organisation même s'ils ne sont pas rattachés à cet agent" do
      organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation])
      other_agent = create(:agent, basic_role_in_organisations: [organisation])
      create_list(:rdv, 3, organisation: organisation, agents: [other_agent])

      expect(described_class.sensitive?(agent)).to be true
    end

    context "quand l'espace impose la double authentification à ses agents" do
      let(:territory) { create(:territory, force_2fa_for_agents: true) }
      let(:organisation) { create(:organisation, territory:) }

      it "est vrai pour un agent basic d'une organisation de l'espace, quel que soit le nombre de RDVs" do
        agent = create(:agent, basic_role_in_organisations: [organisation])

        expect(described_class.sensitive?(agent)).to be true
      end

      it "est vrai pour un admin de l'espace" do
        agent = create(:agent, role_in_territories: [territory])

        expect(described_class.sensitive?(agent)).to be true
      end

      it "est vrai pour un agent présent dans plusieurs espaces dont un seul impose la double authentification" do
        other_organisation = create(:organisation, territory: create(:territory))
        agent = create(:agent, basic_role_in_organisations: [organisation, other_organisation])

        expect(described_class.sensitive?(agent)).to be true
      end
    end

    it "est faux pour un agent basic d'un espace qui n'impose pas la double authentification" do
      organisation = create(:organisation, territory: create(:territory, force_2fa_for_agents: false))
      agent = create(:agent, basic_role_in_organisations: [organisation])

      expect(described_class.sensitive?(agent)).to be false
    end
  end

  describe ".refresh_agent!" do
    it "met à jour sensitive_account immédiatement, sans attendre le job quotidien" do
      organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation], sensitive_account: false)
      create_list(:rdv, 3, organisation: organisation)

      described_class.refresh_agent!(agent)

      expect(agent.reload.sensitive_account).to be true
    end

    it "ne fait rien si la valeur n'a pas changé" do
      agent = create(:agent, sensitive_account: false)

      expect(agent).not_to receive(:update_column)

      described_class.refresh_agent!(agent)
    end
  end
end
