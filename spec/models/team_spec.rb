# frozen_string_literal: true

describe Team, type: :model do
  describe "#to_s" do
    it "return Superteam" do
      agent = build(:team, name: "Superteam")
      expect(agent.to_s).to eq("Superteam")
    end
  end
end
