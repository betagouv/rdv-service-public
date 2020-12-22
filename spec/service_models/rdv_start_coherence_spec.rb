describe RdvStartCoherence, type: :service do
  describe "#rdvs_ending_shortly_before" do
    subject { RdvStartCoherence.new(rdv).rdvs_ending_shortly_before }

    context "ends shortly, agent in common" do
      let!(:agent) { create(:agent) }
      let!(:rdv) { create(:rdv, agents: [agent, build(:agent)], starts_at: Date.today.next_week(:monday).in_time_zone + 16.hours) }
      let!(:rdv2) { create(:rdv, agents: [build(:agent), agent], starts_at: rdv.starts_at - 30.minutes, duration_in_min: 15) }
      it { should include(rdv2) }
    end

    context "ends shortly, no agent in common" do
      let!(:agent) { create(:agent) }
      let!(:rdv) { create(:rdv, agents: [agent], starts_at: Date.today.next_week(:monday).in_time_zone + 16.hours) }
      let!(:rdv2) { create(:rdv, agents: [build(:agent)], starts_at: rdv.starts_at - 30.minutes, duration_in_min: 15) }
      it { should_not include(rdv2) }
    end

    context "does not end shortly" do
      let!(:agent) { create(:agent) }
      let!(:rdv) { create(:rdv, agents: [agent], starts_at: Date.today.next_week(:monday).in_time_zone + 16.hours) }
      let!(:rdv2) { create(:rdv, agents: [agent], starts_at: rdv.starts_at - 2.hours, duration_in_min: 15) }
      it { should_not include(rdv2) }
    end
  end
end
