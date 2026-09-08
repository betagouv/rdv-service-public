RSpec.describe CronJob::RefreshAgentsSensitiveAccountJob, type: :job do
  describe "#perform" do
    before do
      # Stub le seuil pour éviter de créer beaucoup de RDVs
      stub_const("CronJob::RefreshAgentsSensitiveAccountJob::SENSITIVE_RDV_THRESHOLD", 2)
    end

    it "met sensitive_account à true pour un agent admin d'une organisation avec beaucoup de RDVs" do
      organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation], sensitive_account: false)
      create_list(:rdv, 3, organisation: organisation)

      described_class.perform_now

      expect(agent.reload.sensitive_account).to be true
    end

    it "met sensitive_account à true pour un agent accueil d'une organisation avec beaucoup de RDVs" do
      organisation = create(:organisation)
      agent = create(:agent, agent_accueil_role_in_organisations: [organisation], sensitive_account: false)
      create_list(:rdv, 3, organisation: organisation)

      described_class.perform_now

      expect(agent.reload.sensitive_account).to be true
    end

    it "ne met pas sensitive_account à true pour un agent basic (non admin, non accueil) d'une organisation avec beaucoup de RDVs" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation], sensitive_account: false)
      create_list(:rdv, 3, organisation: organisation)

      described_class.perform_now

      expect(agent.reload.sensitive_account).to be false
    end

    it "cumule le volume de RDVs sur plusieurs organisations dont l'agent est admin ou accueil" do
      organisation_1 = create(:organisation)
      organisation_2 = create(:organisation)
      agent = create(:agent,
                     admin_role_in_organisations: [organisation_1],
                     agent_accueil_role_in_organisations: [organisation_2],
                     sensitive_account: false)
      create(:rdv, organisation: organisation_1)
      create(:rdv, organisation: organisation_2)

      described_class.perform_now

      expect(agent.reload.sensitive_account).to be true
    end

    it "met sensitive_account à false pour un agent admin d'une organisation avec peu de RDVs" do
      organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation], sensitive_account: true)

      described_class.perform_now

      expect(agent.reload.sensitive_account).to be false
    end

    it "ne modifie pas sensitive_account des agents sans rôle admin, accueil ou territorial" do
      agent_with_sensitive = create(:agent, sensitive_account: true)
      agent_without_sensitive = create(:agent, sensitive_account: false)

      described_class.perform_now

      expect(agent_with_sensitive.reload.sensitive_account).to be true
      expect(agent_without_sensitive.reload.sensitive_account).to be false
    end

    it "met sensitive_account à true pour les admins de territoire dont une organisation a beaucoup de RDVs" do
      territory = create(:territory)
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, role_in_territories: [territory], sensitive_account: false)
      create_list(:rdv, 3, organisation: organisation)

      described_class.perform_now

      expect(agent.reload.sensitive_account).to be true
    end

    it "cumule le volume de RDVs sur plusieurs organisations d'un même territoire pour un admin de territoire" do
      territory = create(:territory)
      organisation_1 = create(:organisation, territory: territory)
      organisation_2 = create(:organisation, territory: territory)
      agent = create(:agent, role_in_territories: [territory], sensitive_account: false)
      create(:rdv, organisation: organisation_1)
      create(:rdv, organisation: organisation_2)

      described_class.perform_now

      expect(agent.reload.sensitive_account).to be true
    end

    it "met sensitive_account à false pour les admins de territoire dont aucune organisation n'a beaucoup de RDVs" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [territory], sensitive_account: true)

      described_class.perform_now

      expect(agent.reload.sensitive_account).to be false
    end

    it "met sensitive_account à true pour un agent admin d'une organisation rdv_insertion, quel que soit le nombre de RDVs" do
      organisation = create(:organisation, verticale: :rdv_insertion)
      agent = create(:agent, admin_role_in_organisations: [organisation], sensitive_account: false)

      described_class.perform_now

      expect(agent.reload.sensitive_account).to be true
    end

    it "ne marque pas comme sensible un agent avec un rôle basic dans une organisation rdv_insertion" do
      organisation = create(:organisation, verticale: :rdv_insertion)
      agent = create(:agent, basic_role_in_organisations: [organisation], sensitive_account: false)

      described_class.perform_now

      expect(agent.reload.sensitive_account).to be false
    end

    it "cumule les critères : un admin de territoire avec peu de RDVs reste sensible s'il est aussi admin d'une organisation rdv_insertion" do
      territory = create(:territory)
      organisation_rdv_insertion = create(:organisation, verticale: :rdv_insertion)
      agent = create(:agent,
                     role_in_territories: [territory],
                     admin_role_in_organisations: [organisation_rdv_insertion],
                     sensitive_account: false)

      described_class.perform_now

      expect(agent.reload.sensitive_account).to be true
    end
  end
end
