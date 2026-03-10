RSpec.describe DateHelper do
  describe "#relative_date" do
    # def relative_date(date, fallback_format = :short)
    it "returns 23 déc." do
      date = Time.zone.parse("2021-12-23 15:30")
      expect(relative_date(date)).to eq("23 déc.")
    end
    # def relative_date(date, fallback_format = :short)

    it "returns today" do
      now = Time.zone.parse("2021-12-23 15:30")
      travel_to(now)
      date = now
      expect(relative_date(date)).to eq("aujourd’hui")
    end

    # def relative_date(date, fallback_format = :short)
    it "returns tomorrow" do
      now = Time.zone.parse("2021-12-23 15:30")
      travel_to(now)
      date = now + 1.day
      expect(relative_date(date)).to eq("demain")
    end
  end

  describe "#relative_date_with_preposition" do
    it "returns du 23 déc." do
      date = Time.zone.parse("2021-12-23 15:30")
      expect(relative_date_with_preposition(date)).to eq("du 23 déc.")
    end

    it "returns d'aujourd'hui" do
      expect(relative_date_with_preposition(Time.zone.now)).to eq("d'aujourd'hui")
    end

    it "returns de demain" do
      expect(relative_date_with_preposition(Time.zone.tomorrow)).to eq("de demain")
    end
  end

  describe "#soon_date?" do
    it "return false" do
      date = Time.zone.parse("2021-12-23 15:30")
      expect(soon_date?(date)).to be_falsey
    end

    it "return true when date is today" do
      now = Time.zone.parse("2021-12-23 15:30")
      travel_to(now)
      date = now
      expect(soon_date?(date)).to be_truthy
    end

    it "return true when date is tomorrow" do
      now = Time.zone.parse("2021-12-23 15:30")
      travel_to(now)
      date = now + 1.day
      expect(soon_date?(date)).to be_truthy
    end
  end
end
