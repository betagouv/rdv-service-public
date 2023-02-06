# frozen_string_literal: true

describe CanHaveTerritorialAccess, type: :concern do
  describe "#territorial_admin!" do
    it "update agent territorial admin access to true" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [])
      expect { agent.territorial_admin!(territory) }.to change { agent.reload.territorial_admin_in?(territory) }.to(true)
    end
  end

  describe "#remove_territorial_admin!" do
    it "update agent territorial admin access to false" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [territory])
      expect { agent.remove_territorial_admin!(territory) }.to change { agent.reload.territorial_admin_in?(territory) }.to(false)
    end
  end
end
