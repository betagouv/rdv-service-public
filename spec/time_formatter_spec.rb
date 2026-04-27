RSpec.describe TimeFormatter do
  describe ".french_time" do
    it "supports both Time-like objects and Tod::TimeOfDay objects" do
      expect(described_class.french_time(Tod::TimeOfDay.new(8, 15))).to eq("8h15")
      expect(described_class.french_time(Time.zone.parse("2026-04-13 08:15"))).to eq("8h15")
    end

    it "does not show minutes if the are zero" do
      expect(described_class.french_time(Tod::TimeOfDay.parse("09:00"))).to eq("9h")
      expect(described_class.french_time(Tod::TimeOfDay.parse("09:15"))).to eq("9h15")
      expect(described_class.french_time(Tod::TimeOfDay.parse("12:00"))).to eq("12h")
      expect(described_class.french_time(Tod::TimeOfDay.parse("12:45"))).to eq("12h45")
      expect(described_class.french_time(Tod::TimeOfDay.parse("09:05"))).to eq("9h05")
      expect(described_class.french_time(Tod::TimeOfDay.parse("12:05"))).to eq("12h05")
      expect(described_class.french_time(Tod::TimeOfDay.parse("09:01"))).to eq("9h01")
      expect(described_class.french_time(Tod::TimeOfDay.parse("09:09"))).to eq("9h09")
    end
  end

  describe ".french_time_range" do
    it "supports both Time-like objects and Tod::TimeOfDay objects" do
      expect(described_class.french_time_range(Tod::TimeOfDay.new(8, 15), Tod::TimeOfDay.new(11, 30))).to eq("8h15-11h30")
      expect(described_class.french_time_range(Time.zone.parse("2026-04-13 08:15"), Time.zone.parse("2026-04-13 11:30"))).to eq("8h15-11h30")
    end
  end
end
