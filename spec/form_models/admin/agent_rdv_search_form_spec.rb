describe Admin::AgentRdvSearchForm do
  describe "#lieu" do
    it "have a lieu when given" do
      lieu = create(:lieu)
      agent_rdv_search_form = described_class.new(lieu_id: lieu.id)
      expect(agent_rdv_search_form.lieu).to eq(lieu)
    end
  end

  describe "#to_query" do
    it "return query with lieu" do
      organisation = create(:organisation)
      lieu = create(:lieu, organisation: organisation)

      agent_rdv_search_form = described_class.new(organisation_id: organisation.id, lieu_id: lieu.id)
      expected_query = {
        agent_id: nil,
        start: nil,
        end: nil,
        organisation_id: organisation.id,
        lieu_id: lieu.id,
        show_user_details: nil,
        status: nil,
        user_id: nil
      }
      expect(agent_rdv_search_form.to_query).to eq(expected_query)
    end
  end

  describe "#rdvs" do
    it "call Rdv.with_lieu with given lieu" do
      lieu = create(:lieu)
      agent_rdv_search_form = described_class.new(lieu_id: lieu.id)
      expect(Rdv).to receive(:with_lieu).with(lieu)
      agent_rdv_search_form.rdvs
    end

    it "call Rdv.with_agent with given agent" do
      agent = create(:agent)
      agent_rdv_search_form = described_class.new(agent_id: agent.id)
      expect(Rdv).to receive(:with_agent).with(agent)
      agent_rdv_search_form.rdvs
    end

    it "call Rdv.with_user with given user" do
      user = create(:user)
      agent_rdv_search_form = described_class.new(user_id: user.id)
      expect(Rdv).to receive(:with_user).with(user)
      agent_rdv_search_form.rdvs
    end
  end
end
