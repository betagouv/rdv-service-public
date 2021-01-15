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
  end
end
