RSpec.describe CronJob::RefreshAgentsSensitiveAccountJob, type: :job do
  describe "#perform" do
    before do
      # Stub le seuil pour éviter de créer beaucoup de RDVs
      stub_const("CronJob::RefreshAgentsSensitiveAccountJob::SENSITIVE_TERRITORY_RDV_THRESHOLD", 2)
    end

    it "met sensitive_account à true pour les admins de territoires avec beaucoup de RDVs" do
      territory = create(:territory)
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, role_in_territories: [territory], sensitive_account: false)
      create_list(:rdv, 3, organisation: organisation)

      described_class.perform_now

      expect(agent.reload.sensitive_account).to be true
    end

    it "met sensitive_account à false pour les admins de territoires avec peu de RDVs" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [territory], sensitive_account: true)

      described_class.perform_now

      expect(agent.reload.sensitive_account).to be false
    end

    it "ne modifie pas sensitive_account des agents non-admins de territoire" do
      agent_with_sensitive = create(:agent, sensitive_account: true)
      agent_without_sensitive = create(:agent, sensitive_account: false)

      described_class.perform_now

      expect(agent_with_sensitive.reload.sensitive_account).to be true
      expect(agent_without_sensitive.reload.sensitive_account).to be false
    end

    it "met sensitive_account à true pour un agent membre d'une organisation rdv_insertion, quel que soit le nombre de RDVs" do
      organisation = create(:organisation, verticale: :rdv_insertion)
      agent = create(:agent, basic_role_in_organisations: [organisation], sensitive_account: false)

      described_class.perform_now

      expect(agent.reload.sensitive_account).to be true
    end

    it "cumule les critères : un admin de territoire avec peu de RDVs reste sensible s'il est aussi dans une organisation rdv_insertion" do
      territory = create(:territory)
      organisation_rdv_insertion = create(:organisation, verticale: :rdv_insertion)
      agent = create(:agent,
                     role_in_territories: [territory],
                     basic_role_in_organisations: [organisation_rdv_insertion],
                     sensitive_account: false)

      described_class.perform_now

      expect(agent.reload.sensitive_account).to be true
    end
  end
end
