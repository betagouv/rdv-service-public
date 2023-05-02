# frozen_string_literal: true

describe NextAvailabilityService, type: :service do
  let(:today) { Date.new(2021, 3, 18) }
  let(:now) { Time.zone.parse("20210318 8:23") }

  let(:organisation) { create(:organisation) }
  let(:lieu) { create(:lieu, organisation: organisation) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:motif) { create(:motif, name: "Vaccination", default_duration_in_min: 30, organisation: organisation) }

  before { travel_to(now) }

  describe "#find" do
    describe "regular case" do
      it "works" do
        create(:plage_ouverture,
               motifs: [motif], lieu: lieu, agent: agent, organisation: organisation,
               first_day: today + 8.days, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
        next_available = described_class.find(motif, lieu, [], from: today)
        expect(next_available.starts_at).to eq((today + 8.days).in_time_zone + 9.hours)
      end
    end

    describe "with an overlapping absence" do
      it "planned" do
        create(:plage_ouverture,
               motifs: [motif], lieu: lieu, agent: agent, organisation: organisation,
               first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
        create(:absence,
               agent: agent,
               first_day: today, start_time: Tod::TimeOfDay.new(9), end_day: today, end_time: Tod::TimeOfDay.new(12, 0))

        next_available = described_class.find(motif, lieu, [], from: today)
        expect(next_available).to be_nil
      end

      it "when plage_ouverture is recurrence" do
        recurrence = Montrose.every(:month, starts: today)
        create(:plage_ouverture,
               motifs: [motif], lieu: lieu, agent: agent, organisation: organisation,
               first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11),
               recurrence: recurrence)
        create(:absence,
               agent: agent,
               first_day: today, start_time: Tod::TimeOfDay.new(9), end_day: today, end_time: Tod::TimeOfDay.new(12, 0))

        next_available = described_class.find(motif, lieu, [], from: today)
        expect(next_available.starts_at).to eq(today.in_time_zone + 1.month + 9.hours)
      end
    end

    describe "with an overlapping rdv" do
      it "look at future's RDV an cancel creneau" do
        create(:plage_ouverture,
               motifs: [motif], lieu: lieu, agent: agent, organisation: organisation,
               first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
        create(:rdv,
               agents: [agent],
               organisation: organisation,
               lieu: lieu,
               motif: motif,
               starts_at: today.in_time_zone + 9.hours, duration_in_min: 120,
               status: "unknown")
        next_creneau = described_class.find(motif, lieu, [], from: today)
        expect(next_creneau).to be_nil
      end

      it "doesnt look a cancelled's RDV" do
        create(:plage_ouverture,
               motifs: [motif], lieu: lieu, agent: agent, organisation: organisation,
               first_day: (today + 8.days), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
        create(:rdv,
               agents: [agent],
               organisation: organisation,
               lieu: lieu,
               motif: motif,
               starts_at: (today + 8.days).in_time_zone + 9.hours, duration_in_min: 120,
               status: "revoked")

        next_creneau = described_class.find(motif, lieu, [], from: today)
        expect(next_creneau.starts_at).to eq((today + 8.days).in_time_zone + 9.hours)
      end

      it "returns a next creneau when plage_ouverture is recurrence" do
        create(:rdv,
               agents: [agent],
               organisation: organisation,
               lieu: lieu,
               motif: motif,
               starts_at: today.in_time_zone + 9.hours, duration_in_min: 120,
               status: "unknown")

        create(:plage_ouverture,
               motifs: [motif], lieu: lieu, agent: agent, organisation: organisation,
               first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11),
               recurrence: Montrose.every(:month, starts: today))

        next_creneau = described_class.find(motif, lieu, [], from: today)
        expect(next_creneau.starts_at).to eq(today.in_time_zone + 1.month + 9.hours)
      end
    end

    describe "when the day at min booking delay is the same day as the plage ouverture" do
      let!(:motif) do
        create(:motif,
               name: "Vaccination", default_duration_in_min: 30, organisation: organisation,
               min_public_booking_delay: 1.week.from_now, max_public_booking_delay: 7.months.from_now)
      end

      let!(:plage_ouverture) do
        create(:plage_ouverture,
               motifs: [motif], lieu: lieu, agent: agent, organisation: organisation,
               first_day: today + 1.week, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11),
               recurrence: Montrose.every(:week, starts: 1.week.from_now))
      end

      context "when now is later than the plage d'ouverture" do
        let!(:now) { Time.zone.parse("20210318 17:00") }

        it "returns a next creneau the week after the first occurrence" do
          next_creneau = described_class.find(motif, lieu, [], from: Time.zone.at(motif.min_public_booking_delay))
          expect(next_creneau.starts_at).to eq(today.in_time_zone + 2.weeks + 9.hours)
        end
      end
    end

    describe "with several agents" do
      let(:other_agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let(:other_agent_start_day) { today + 7.days }

      it "returns the first availability for any agent" do
        create(:plage_ouverture,
               motifs: [motif], lieu: lieu,
               first_day: other_agent_start_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11),
               agent: other_agent, organisation: organisation)
        wanted_agents = [agent.id, other_agent.id]
        next_creneau = described_class.find(motif, lieu, wanted_agents, from: today)
        expect(next_creneau.starts_at).to eq(today + 7.days + 9.hours)
      end

      it "returns the availability of a specific agent among two" do
        create(:plage_ouverture,
               motifs: [motif], lieu: lieu,
               first_day: other_agent_start_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11),
               agent: other_agent, organisation: organisation)
        wanted_agents = [other_agent.id]
        next_creneau = described_class.find(motif, lieu, wanted_agents, from: today)
        expect(next_creneau.starts_at).to eq(other_agent_start_day + 9.hours)
      end
    end
  end
end
