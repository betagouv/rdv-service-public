# frozen_string_literal: true

describe CanHaveTerritorialAccess, type: :concern do
  describe "#territorial_admin!" do
    it "update agent territorial admin access to true" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [])
      agent.territorial_admin!(territory)
      expect(agent.reload.territorial_admin_in?(territory)).to eq(true)
    end
  end

  describe "#remove_territorial_admin!" do
    it "update agent territorial admin access to false" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [territory])
      agent.remove_territorial_admin!(territory)
      expect(agent.reload.territorial_admin_in?(territory)).to eq(false)
    end
  end
end
