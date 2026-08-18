RSpec.describe Notifiers::AgentsConcern do
  describe ".soon_date?" do
    it "return false" do
      date = Time.zone.parse("2021-12-23 15:30")
      expect(described_class.soon_date?(date)).to be_falsey # rubocop:disable RSpec/PredicateMatcher
    end

    it "return true when date is today" do
      now = Time.zone.parse("2021-12-23 15:30")
      travel_to(now)
      date = now
      expect(described_class.soon_date?(date)).to be_truthy # rubocop:disable RSpec/PredicateMatcher
    end

    it "return true when date is tomorrow" do
      now = Time.zone.parse("2021-12-23 15:30")
      travel_to(now)
      date = now + 1.day
      expect(described_class.soon_date?(date)).to be_truthy # rubocop:disable RSpec/PredicateMatcher
    end
  end
end
