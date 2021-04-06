describe RdvsOverlapping, type: :service do
  describe "#rdvs_overlapping_rdv" do
    it "return rdvs that end during rdv" do
      now = Time.zone.parse("2020-12-23 12h40")
      travel_to(now)
      agent = create(:agent)
      overlapped_rdv = create(:rdv, agents: [agent], starts_at: now + 1.day, duration_in_min: 30)
      created_rdv = create(:rdv, agents: [agent], starts_at: now + 1.day + 15.minutes)
      expect(described_class.new(created_rdv).rdvs_overlapping_rdv).to eq([overlapped_rdv])
      travel_back
    end

    it "return rdvs that starts during rdv" do
      now = Time.zone.parse("2020-12-23 12h40")
      travel_to(now)
      agent = create(:agent)
      overlapped_rdv = create(:rdv, agents: [agent], starts_at: now + 1.day, duration_in_min: 30)
      created_rdv = create(:rdv, agents: [agent], starts_at: now + 1.day - 15.minutes, duration_in_min: 30)
      expect(described_class.new(created_rdv).rdvs_overlapping_rdv).to eq([overlapped_rdv])
      travel_back
    end

    it "return rdvs that starts before and end after rdv" do
      now = Time.zone.parse("2020-12-23 12h40")
      travel_to(now)
      agent = create(:agent)
      overlapped_rdv = create(:rdv, agents: [agent], starts_at: now + 1.day - 30.minutes, duration_in_min: 60)
      created_rdv = create(:rdv, agents: [agent], starts_at: now + 1.day - 15.minutes, duration_in_min: 30)
      expect(described_class.new(created_rdv).rdvs_overlapping_rdv).to eq([overlapped_rdv])
      travel_back
    end

    it "do not return rdv that starts just at rdv's end" do
      now = Time.zone.parse("2020-12-23 12h40")
      travel_to(now)
      agent = create(:agent)
      created_rdv = create(:rdv, agents: [agent], starts_at: now + 1.day, duration_in_min: 30)
      create(:rdv, agents: [agent], starts_at: now + 1.day + 30.minutes, duration_in_min: 30)
      expect(described_class.new(created_rdv).rdvs_overlapping_rdv).to eq([])
      travel_back
    end

    it "do not return rdv that end just at rdv's start" do
      now = Time.zone.parse("2020-12-23 12h40")
      travel_to(now)
      agent = create(:agent)
      create(:rdv, agents: [agent], starts_at: now + 1.day - 30.minutes, duration_in_min: 30)
      created_rdv = create(:rdv, agents: [agent], starts_at: now + 1.day, duration_in_min: 30)
      expect(described_class.new(created_rdv).rdvs_overlapping_rdv).to eq([])
      travel_back
    end

    it "returns RDV with exact same times" do
      now = Time.zone.parse("2020-12-23 12h40")
      travel_to(now)
      agent = create(:agent)
      existing_rdv = create(:rdv, agents: [agent], starts_at: now + 1.day, duration_in_min: 30)
      new_rdv = build(:rdv, agents: [agent], starts_at: now + 1.day, duration_in_min: 30)
      expect(described_class.new(new_rdv).rdvs_overlapping_rdv).to eq([existing_rdv])
      travel_back
    end
  end
end
