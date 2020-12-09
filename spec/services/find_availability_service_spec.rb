describe FindAvailabilityService, type: :service do
  let!(:organisation) { create(:organisation) }
  let!(:motif) { create(:motif, name: "Vaccination", default_duration_in_min: 30, reservable_online: reservable_online, organisation: organisation) }
  let(:reservable_online) { true }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let(:today) { Date.new(2019, 9, 19) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent, organisation: organisation) }
  let(:now) { today.to_time }

  before { travel_to(now) }
  after { travel_back }

  describe ".next_availability_for_motif_and_lieu" do
    let(:motif_name) { motif.name }
    let(:from) { today }

    subject do
      FindAvailabilityService.perform_with(motif_name, lieu, from)
    end

    it { expect(subject.starts_at).to eq(Time.zone.local(2019, 9, 19, 9, 0)) }

    describe "with not reservable_online motif" do
      let(:reservable_online) { false }

      it { should eq(nil) }
    end

    describe "with absence" do
      let!(:absence) { create(:absence, agent: agent, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(12, 0), organisation: organisation) }

      it { should eq(nil) }

      describe "when plage_ouverture is recurrence" do
        before { plage_ouverture.update(recurrence: Montrose.every(:month, starts: plage_ouverture.first_day)) }

        it { expect(subject.starts_at).to eq(Time.zone.local(2019, 10, 19, 9, 0)) }
      end
    end

    describe "with rdv" do
      let!(:rdv) { create(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 120, agents: [agent], organisation: organisation, lieu: lieu) }

      it { should eq(nil) }

      context "which is cancelled" do
        let!(:rdv) { create(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 30), duration_in_min: 30, agents: [agent], cancelled_at: Time.zone.local(2019, 9, 20, 9, 30), organisation: organisation, lieu: lieu) }

        it { expect(subject.starts_at).to eq(Time.zone.local(2019, 9, 19, 9, 0)) }
      end

      describe "when plage_ouverture is recurrence" do
        before { plage_ouverture.update(recurrence: Montrose.every(:month, starts: plage_ouverture.first_day)) }

        it { expect(subject.starts_at).to eq(Time.zone.local(2019, 10, 19, 9, 0)) }
      end
    end
  end
end
