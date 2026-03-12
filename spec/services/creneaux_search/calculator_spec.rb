RSpec.describe CreneauxSearch::Calculator do
  subject(:available_slots) { described_class.available_slots(motif:, lieu:, date_range:) }

  let(:friday) { Time.zone.parse("20210430 8:00") }
  let(:date_range) { first_day..Date.new(2021, 5, 8) }
  let(:first_day) { Date.new(2021, 5, 3) }
  let(:motif) { create(:motif, default_duration_in_min: 60, organisation: organisation) }
  let(:organisation) { create(:organisation) }
  let(:lieu) { create(:lieu, organisation: organisation) }

  before { travel_to(friday) }

  context "when there is no plage_ouverture" do
    it { is_expected.to eq([]) }
  end

  context "with a plage d'ouverture lasting 2 hours" do
    before do
      create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
    end

    it "returns 2 slots" do
      expect(available_slots.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00", "10:00"])
      expect(available_slots.first.class.to_s).to eq("Creneau")
    end

    context "when passing a duration_in_min" do
      subject(:available_slots) { described_class.available_slots(motif:, lieu:, date_range:, duration_in_min: 25) }

      it "overrides the motif's default duration, and creates slots of the correct length" do
        expect(available_slots.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00", "09:25", "09:50", "10:15", "10:40"])
      end
    end

    context "when the required lieu doesn't match the plage_ouverture" do
      subject(:available_slots) { described_class.available_slots(motif:, lieu: other_lieu, date_range:) }

      let(:other_lieu) { create(:lieu, organisation:) }

      it { is_expected.to eq([]) }
    end
  end

  context "when the plage d'ouverture has already started" do
    let(:date_range) { friday..Date.new(2021, 5, 1) }

    it "returns the creneaux for the reste of the plage d'ouverture" do
      create(:plage_ouverture, :weekdays, motifs: [motif], first_day: friday.to_date, start_time: Tod::TimeOfDay.new(7), end_time: Tod::TimeOfDay.new(11), lieu: lieu)
      slots = described_class.available_slots(motif:, lieu:, date_range:)
      expect(slots.first.starts_at.iso8601).to eq("2021-04-30T08:00:00+02:00")
    end
  end

  context "when date range starts before today" do
    let(:today) { Date.new(2022, 7, 13) }
    let(:yesterday) { today - 1.day }
    let(:two_days_ago) { today - 2.days }
    let(:seven_days_from_now) { today + 7.days }

    before do
      travel_to(today)

      # create plage ouvertures in the 3 last days
      create(:plage_ouverture, motifs: [motif], first_day: two_days_ago,  start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), lieu: lieu)
      create(:plage_ouverture, motifs: [motif], first_day: yesterday,     start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), lieu: lieu)
      create(:plage_ouverture, motifs: [motif], first_day: today,         start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), lieu: lieu)
    end

    it "only returns slots in the future" do
      slots = described_class.available_slots(motif:, lieu:, date_range: two_days_ago..seven_days_from_now)

      # Only today's slots are returned, not the ones from the past, even though they are included in the range
      expect(slots.map(&:starts_at)).to eq([Time.zone.parse("2022-07-13 09:00:00"), Time.zone.parse("2022-07-13 10:00:00")])
    end

    context "when date range also ends before today" do
      it "returns no result" do
        date_range_in_the_past = (today - 10.days)..(today - 3.days)
        slots = described_class.available_slots(motif:, lieu:, date_range: date_range_in_the_past)

        # No slot is returned since all slots are in the past
        expect(slots).to be_empty
      end
    end
  end

  context "when asking for slots that may start right now" do
    let(:motif) do
      create(:motif, default_duration_in_min: 60, organisation: organisation, min_public_booking_delay: 45 * 60)
    end

    it "returns only slots that start in the future, without minimum booking delay" do
      create(:plage_ouverture, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(12) + 1.second, lieu: lieu)

      # The plage_ouverture are not always sorted, so neither are the slots, so we can't just remove the first slots
      create(:plage_ouverture, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(18), end_time: Tod::TimeOfDay.new(20) + 1.second, lieu: lieu)
      create(:plage_ouverture, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(17) + 1.second, lieu: lieu)

      travel_to(Time.zone.local(2021, 5, 3, 15, 3, 0))

      slots = described_class.available_slots(motif:, lieu:, date_range:)

      # The current time is 15:03
      # The available plages ouvertures are 9:00-12:00, 14:00-17:00, and 18:00-20:00
      # We round up the rdv time to the closest 5mn, so the first possible creneau is at 15:05.

      expect(slots.map(&:starts_at)).to contain_exactly(
        Time.zone.local(2021, 5, 3, 15, 5, 0),
        Time.zone.local(2021, 5, 3, 18, 0, 0),
        Time.zone.local(2021, 5, 3, 19, 0, 0)
      )
    end
  end

  context "when there is an absence and a rdv overlapping at the beginning of the plage ouverture" do
    # Une plage d'ouverture de 9h à 11h,
    # Un rdv de 9h à 10h
    # Une absence de 9h15 à 9h45 (par exemple une absence récurrente créée après le rdv, où on suppose que l'agent accepte de faire une exception)
    before do
      plage_ouverture = create(:plage_ouverture, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), lieu: lieu)
      create(:rdv, agents: [plage_ouverture.agent], motif: motif, starts_at: Time.zone.local(2021, 5, 3, 9, 0, 0), duration_in_min: 60, organisation:)
      create(:absence, agent: plage_ouverture.agent, first_day: first_day, end_day: first_day, start_time: Tod::TimeOfDay.new(9, 15), end_time: Tod::TimeOfDay.new(9, 45))
    end

    it "returns the slots in the free part of the plage ouverture" do
      slots = described_class.available_slots(motif:, lieu:, date_range:)
      expect(slots.map(&:starts_at).map(&:hour)).to eq([10])
    end
  end

  context "for a motif not requiring a lieu" do
    subject(:available_slots) { described_class.available_slots(motif:, lieu: nil, date_range:) }

    let(:motif) { create(:motif, :by_phone, default_duration_in_min: 60, organisation:) }

    context "with one plage_ouverture with a lieu and one without" do
      before do
        create(:plage_ouverture, lieu: nil, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(10))
        create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(15))
      end

      it "returns slots for both plage_ouverture" do
        expect(available_slots.map(&:starts_at).map(&:hour)).to eq([9, 14])
      end
    end
  end

  it "returns all plage_ouverture for the range" do
    create(:plage_ouverture, lieu:, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
    create(:plage_ouverture, lieu:, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

    expect(available_slots.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00", "10:00", "09:00", "10:00"])
  end

  it "returns only without recurrence PO where first_day is in range" do
    create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(10))
    create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day + 1.month, start_time: Tod::TimeOfDay.new(10), end_time: Tod::TimeOfDay.new(11))

    expect(available_slots.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00"])
  end

  it "returns only créneaux matching the motif" do
    create(:plage_ouverture, lieu:, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(10))
    # create(:plage_ouverture, lieu:, motifs: [create(:motif, organisation: organisation)], first_day: first_day, start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(15))
    create(:plage_ouverture, lieu:, motifs: [create(:motif, organisation: organisation)], first_day: first_day, start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(15))

    expect(available_slots.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00"])
  end

  it "doesn't return créneaux for expired plage ouverture" do
    create(:plage_ouverture, lieu:, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(10))
    create(:plage_ouverture, lieu:, motifs: [motif], first_day: friday - 1.day, start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(15))

    expect(available_slots.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00"])
  end

  it "returns créneaux for PO with recurrences that always running" do
    create(:plage_ouverture, :weekdays, lieu:, motifs: [motif], first_day: first_day - 1.day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(10))

    expect(available_slots.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00", "09:00", "09:00", "09:00", "09:00"])
  end

  context "when asking for the créneaux of a given agent" do
    subject(:available_slots) { described_class.available_slots(motif:, lieu:, date_range:, agents: [agent]) }

    let(:agent) { create(:agent, organisations: [organisation]) }
    let(:other_agent) { create(:agent, organisations: [organisation]) }

    it "returns créneaux for the given agent_ids" do
      create(:plage_ouverture, agent: agent, lieu:, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(10))
      create(:plage_ouverture, agent: other_agent, lieu:, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(15))

      expect(available_slots.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00"])
    end
  end

  it "excludes créneaux for agents with a pending invitation" do
    normal_agent = create(:agent, organisations: [organisation])
    intervenant = create(:agent, :intervenant, organisations: [organisation])

    agent_with_pending_invitation = create(:agent, :invitation_not_accepted, organisations: [organisation])

    create(:plage_ouverture, agent: normal_agent, start_time: Tod::TimeOfDay.new(9), lieu: lieu, motifs: [motif], first_day: first_day, end_time: Tod::TimeOfDay.new(10))
    create(:plage_ouverture, agent: intervenant, start_time: Tod::TimeOfDay.new(10), lieu: lieu, motifs: [motif], first_day: first_day, end_time: Tod::TimeOfDay.new(11))

    create(:plage_ouverture, agent: agent_with_pending_invitation, start_time: Tod::TimeOfDay.new(14), lieu: lieu, motifs: [motif], first_day: first_day, end_time: Tod::TimeOfDay.new(15))

    expect(available_slots.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00", "10:00"])
  end

  context "with an absence over range" do
    before do
      plage_ouverture = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)

      create(:absence, agent: plage_ouverture.agent, first_day: first_day, start_time: Tod::TimeOfDay.new(8), end_time: Tod::TimeOfDay.new(12))
    end

    it { is_expected.to eq([]) }
  end

  context "without recurrence" do
    context "when po is out of range" do
      let(:date_range) { (friday + 3.days)..(friday + 10.days) }

      before do
        create(:plage_ouverture, motifs: [motif], first_day: friday, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
      end

      it { is_expected.to eq([]) }
    end

    context "when occurrence of po is in range" do
      let(:date_range) { (friday + 3.days)..(friday + 10.days) }

      before do
        create(:plage_ouverture, motifs: [motif], lieu:, first_day: friday + 4.days, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
      end

      it "returns créneaux" do
        expect(available_slots.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00", "10:00"])
      end
    end

    context "when po is in range starting today" do
      let(:friday) { Time.zone.parse("20210430 12:00") }
      let(:date_range) { friday..(friday + 10.days) }

      it "return occurrence minus already past time of today of po" do
        create(:plage_ouverture, motifs: [motif], lieu:, first_day: friday, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(14))
        expect(available_slots.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["12:00", "13:00"])
      end
    end
  end

  context "with recurrence" do
    context "when po is out of range" do
      let(:date_range) { (friday + 3.days)..(friday + 10.days) }

      before do
        create(:plage_ouverture, motifs: [motif], lieu:, first_day: friday + 14.days, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11),
                                 recurrence: Montrose.every(:week, starts: friday + 14.days, interval: 1))
      end

      it { is_expected.to eq([]) }
    end

    context "when PO is in range" do
      let(:date_range) { (friday + 3.days)..(friday + 10.days) }

      before do
        create(:plage_ouverture, motifs: [motif], lieu:, first_day: friday - 14.days, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11),
                                 recurrence: Montrose.every(:week, starts: friday - 14.days, interval: 1))
      end

      it "return occurrence" do
        expect(available_slots.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00", "10:00"])
      end
    end
  end
end
