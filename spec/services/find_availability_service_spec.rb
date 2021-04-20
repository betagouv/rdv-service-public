describe FindAvailabilityService, type: :service do
  let!(:organisation) { create(:organisation) }
  let!(:motif) { create(:motif, name: "Vaccination", default_duration_in_min: 30, reservable_online: reservable_online, organisation: organisation) }
  let(:reservable_online) { true }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let(:today) { Date.new(2021, 3, 18) }
  let(:now) { today.to_time }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:plage_ouverture) do
    travel_to(now) do # important so that expired_cached is set correctly
      create(:plage_ouverture, motifs: [motif], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent, organisation: organisation)
    end
  end

  before { travel_to(now) }

  after { travel_back }

  describe ".next_availability_for_motif_and_lieu" do
    subject do
      described_class.perform_with(motif_name, lieu, from)
    end

    let(:motif_name) { motif.name }
    let(:from) { today }

    it { expect(subject.starts_at).to eq(today.in_time_zone + 9.hours) }

    describe "with not reservable_online motif" do
      let(:reservable_online) { false }

      it { is_expected.to eq(nil) }
    end

    describe "with absence" do
      let!(:absence) { create(:absence, agent: agent, first_day: today, start_time: Tod::TimeOfDay.new(9, 0), end_day: today, end_time: Tod::TimeOfDay.new(12, 0), organisation: organisation) }

      it { is_expected.to eq(nil) }

      describe "when plage_ouverture is recurrence" do
        before { plage_ouverture.update(recurrence: Montrose.every(:month, starts: plage_ouverture.first_day)) }

        it { expect(subject.starts_at).to eq(today.in_time_zone + 1.month + 9.hours) }
      end
    end

    describe "with rdv" do
      let!(:rdv) { create(:rdv, starts_at: today.in_time_zone + 9.hours, duration_in_min: 120, agents: [agent], organisation: organisation, lieu: lieu) }

      it { is_expected.to eq(nil) }

      context "which is cancelled" do
        let!(:rdv) do
          create(:rdv, starts_at: today.in_time_zone + 9.hours + 30.minutes, duration_in_min: 30, agents: [agent], cancelled_at: Time.zone.local(2019, 9, 20, 9, 30), organisation: organisation,
                       lieu: lieu)
        end

        it { expect(subject.starts_at).to eq(today.in_time_zone + 9.hours) }
      end

      describe "when plage_ouverture is recurrence" do
        before { plage_ouverture.update(recurrence: Montrose.every(:month, starts: plage_ouverture.first_day)) }

        it { expect(subject.starts_at).to eq(today.in_time_zone + 1.month + 9.hours) }
      end
    end
  end
end
