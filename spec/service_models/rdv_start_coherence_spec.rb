describe RdvStartCoherence, type: :service do
  describe "#rdvs_ending_shortly_before" do
    subject { RdvStartCoherence.new(rdv).rdvs_ending_shortly_before }

    context "ends shortly before, agent in common" do
      let!(:agent) { create(:agent) }
      let!(:rdv) { create(:rdv, agents: [agent, build(:agent)], starts_at: Date.today.next_week(:monday).in_time_zone + 16.hours) }
      let!(:rdv2) { create(:rdv, agents: [build(:agent), agent], starts_at: rdv.starts_at - 30.minutes, duration_in_min: 15) }
      it { should include(rdv2) }
    end

    context "ends shortly before but is canceled" do
      let!(:agent) { create(:agent) }
      let!(:rdv) { create(:rdv, agents: [agent], starts_at: Date.today.next_week(:monday).in_time_zone + 16.hours) }
      let!(:rdv2) { create(:rdv, agents: [agent], starts_at: rdv.starts_at - 30.minutes, duration_in_min: 15, status: :excused, cancelled_at: 10.minutes.ago) }
      it { should_not include(rdv2) }
    end

    context "ends shortly but is in the past" do
      let!(:agent) { create(:agent) }
      let!(:rdv) { create(:rdv, agents: [agent], starts_at: Date.today.next_week(:monday).in_time_zone + 16.hours) }
      let!(:rdv2) { create(:rdv, agents: [agent], starts_at: rdv.starts_at - 30.minutes, duration_in_min: 15) }
      before { travel_to(rdv.starts_at - 10.minutes) }
      after { travel_back }
      it { should_not include(rdv2) }
    end

    context "ends shortly before but no agent in common" do
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
