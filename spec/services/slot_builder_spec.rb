# frozen_string_literal: true

describe SlotBuilder, type: :service do
  let(:friday) { Time.zone.parse("20210430 8:00") }
  let(:organisation) { create(:organisation) }
  let(:lieu) { create(:lieu, organisation: organisation) }

  before do
    travel_to(friday)
  end

  describe "#available_slots" do
    let(:motif) { create(:motif, default_duration_in_min: 60, organisation: organisation) }
    let(:first_day) { Date.new(2021, 5, 3) }
    let(:date_range) { first_day..Date.new(2021, 5, 8) }

    it "returns 2 slots with a basic context" do
      create(:plage_ouverture, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes, lieu: lieu)
      slots = described_class.available_slots(motif, lieu, date_range)
      expect(slots.map(&:starts_at).map(&:hour)).to eq([9, 10])
    end

    it "return Creneaux object" do
      create(:plage_ouverture, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes, lieu: lieu)
      slots = described_class.available_slots(motif, lieu, date_range)
      expect(slots.map(&:class).map(&:to_s).uniq).to eq(["Creneau"])
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
        slots = described_class.available_slots(motif, lieu, two_days_ago..seven_days_from_now)

        # Only today's slots are returned, not the ones from the past, even though they are included in the range
        expect(slots.map(&:starts_at)).to eq([Time.zone.parse("2022-07-13 09:00:00"), Time.zone.parse("2022-07-13 10:00:00")])
      end

      context "when date range also ends before today" do
        it "returns no result" do
          date_range_in_the_past = (today - 10.days)..(today - 3.days)
          slots = described_class.available_slots(motif, lieu, date_range_in_the_past)

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

        slots = described_class.available_slots(motif, lieu, date_range)

        # The current time is 15:03
        # The available plages ouvertures are 9:00-12:00, 14:00-17:00, and 18:00-20:00
        # We round up the rdv time to the closest 5mn, so the first possible creneau is at 15:05.

        expect(slots.map(&:starts_at)).to match_array([
                                                        Time.zone.local(2021, 5, 3, 15, 5, 0),
                                                        Time.zone.local(2021, 5, 3, 18, 0, 0),
                                                        Time.zone.local(2021, 5, 3, 19, 0, 0),
                                                      ])
      end
    end
  end

  describe "#plage_ouvertures_for" do
    let(:motif) { create(:motif, default_duration_in_min: 60, organisation: organisation) }
    let(:first_day) { Date.new(2021, 5, 3) }
    let(:date_range) { first_day..Date.new(2021, 5, 8) }

    it "return empty without plage_ouverture" do
      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range, [])

      expect(plage_ouvertures).to eq([])
    end

    it "return plage_ouverture that match when a lieu is given" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range, [])

      expect(plage_ouvertures).to eq([matching_po])
    end

    it "return plage_ouverture that match without no lieu given" do
      motif = create(:motif, :by_phone, default_duration_in_min: 60, organisation: organisation)
      matching_po1 = create(:plage_ouverture, lieu: nil, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      matching_po2 = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)

      plage_ouvertures = described_class.plage_ouvertures_for(motif, nil, date_range, [])

      expect(plage_ouvertures).to match([matching_po1, matching_po2])
    end

    it "returns all plage_ouverture for the range" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      other_matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range, [])

      expect(plage_ouvertures).to eq([matching_po, other_matching_po])
    end

    it "returns only without recurrence PO where first_day is in range" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day + 1.month, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range, [])

      expect(plage_ouvertures).to eq([matching_po])
    end

    it "returns only same lieu PO" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      create(:plage_ouverture, lieu: create(:lieu), motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range, [])

      expect(plage_ouvertures).to eq([matching_po])
    end

    it "returns only same motif PO" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      create(:plage_ouverture, lieu: lieu, motifs: [create(:motif, organisation: organisation)], first_day: first_day, start_time: Tod::TimeOfDay.new(9),
                               end_time: Tod::TimeOfDay.new(11))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range, [])

      expect(plage_ouvertures).to eq([matching_po])
    end

    it "returns only not_expired PO" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: friday - 1.day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range, [])

      expect(plage_ouvertures).to eq([matching_po])
    end

    it "returns PO with recurrences that always running" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      recurring_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day - 1.day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11),
                                              recurrence: Montrose.every(:week, starts: first_day - 1.day))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range, [])
      expect(plage_ouvertures.sort).to eq([matching_po, recurring_po].sort)
    end

    it "returns without recurrence PO that start in range" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day - 1.day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range, [])

      expect(plage_ouvertures).to eq([matching_po])
    end

    it "returns filtered PO on agent_ids given" do
      other_agent = create(:agent, organisations: [organisation])
      agent = create(:agent, organisations: [organisation])
      matching_po = create(:plage_ouverture, agent_id: other_agent.id, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9),
                                             end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      create(:plage_ouverture, agent_id: agent.id, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range, [other_agent.id])

      expect(plage_ouvertures).to eq([matching_po])
    end
  end

  describe "#free_times_from" do
    it "return an empty hash without plage_ouvertures" do
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)
      expect(described_class.free_times_from([], range)).to eq({})
    end

    it "calls calculate_free_times for given plage_ouvertures" do
      plage_ouverture = build(:plage_ouverture)
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)
      expect(described_class).to receive(:calculate_free_times).with(plage_ouverture, range)
      described_class.free_times_from([plage_ouverture], range)
    end
  end

  describe "#calculate_free_times" do
    let(:motif) { create(:motif, default_duration_in_min: 60, organisation: organisation) }
    let(:agent) { create(:agent, organisations: [organisation]) }

    it "return one free time from plage ouverture date range" do
      plage_ouverture = build(:plage_ouverture, first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)
      expect(described_class.calculate_free_times(plage_ouverture, range)).to eq([Time.zone.parse("20211027 9:00")..Time.zone.parse("20211027 11:00")])
    end

    it "return plage ouverture slot minus rdv duration" do
      starts_at = Time.zone.parse("20211027 9:00")
      ends_at = Time.zone.parse("20211027 11:00")
      rdv = create(:rdv, motif: motif, starts_at: starts_at, agents: [agent])
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent, motifs: [motif])
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)

      expected_ranges = [rdv.ends_at..ends_at]
      expect(described_class.calculate_free_times(plage_ouverture, range)).to eq(expected_ranges)
    end

    it "return plage ouverture slot minus RDV duration that overlap po when RDV starts before PO" do
      starts_at = Time.zone.parse("20211027 9:00")
      ends_at = Time.zone.parse("20211027 11:00")
      rdv = create(:rdv, motif: motif, starts_at: starts_at - 30.minutes, agents: [agent])
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent)
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)

      expected_ranges = [rdv.ends_at..ends_at]
      expect(described_class.calculate_free_times(plage_ouverture, range)).to eq(expected_ranges)
    end

    it "return plage ouverture slots minus 2 RDV duration that overlap po" do
      starts_at = Time.zone.parse("20211027 9:00")
      ends_at = Time.zone.parse("20211027 11:00")
      rdv = create(:rdv, motif: motif, starts_at: starts_at - 30.minutes, agents: [agent])
      other_rdv = create(:rdv, motif: motif, starts_at: starts_at + 45.minutes, agents: [agent])
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent)
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)

      expected_ranges = [rdv.ends_at..other_rdv.starts_at, other_rdv.ends_at..ends_at]
      expect(described_class.calculate_free_times(plage_ouverture, range)).to eq(expected_ranges)
    end

    it "return plage ouverture slots minus 2 Absences duration that overlap po" do
      starts_at = Time.zone.parse("20211027 9:00")
      ends_at = Time.zone.parse("20211027 11:00")

      s8h30 = Time.zone.parse("20211027 8:30")
      e9h30 = Time.zone.parse("20211027 9:30")
      s9h45 = Time.zone.parse("20211027 9:45")
      e10h45 = Time.zone.parse("20211027 10:45")

      create(:absence, first_day: s8h30.to_date, start_time: Tod::TimeOfDay.new(s8h30.hour, s8h30.min), end_day: e9h30.to_date, end_time: Tod::TimeOfDay.new(e9h30.hour, e9h30.min), agent: agent)
      create(:absence, first_day: s9h45.to_date, start_time: Tod::TimeOfDay.new(s9h45.hour, s9h45.min), end_day: e10h45.to_date, end_time: Tod::TimeOfDay.new(e10h45.hour, e10h45.min), agent: agent)
      plage_ouverture = create(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent, organisation: organisation)
      range = Date.new(2021, 10, 25)..Date.new(2021, 10, 30)

      expected_ranges = [e9h30..s9h45, e10h45..ends_at]
      expect(described_class.calculate_free_times(plage_ouverture, range)).to eq(expected_ranges)
    end

    it "returns plage ouverture's 3 occurrences of range" do
      starts_at = Time.zone.parse("20211026 9:00")
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent,
                                                recurrence: Montrose.every(:week, starts: starts_at.to_date - 1.day, day: [1, 2, 4, 5]))
      range = Date.new(2021, 10, 25)..Date.new(2021, 10, 30)

      expected_ranges = [
        (Time.zone.parse("2021-10-26 9:00")..Time.zone.parse("2021-10-26 11:00")),
        (Time.zone.parse("2021-10-28 9:00")..Time.zone.parse("2021-10-28 11:00")),
        (Time.zone.parse("2021-10-29 9:00")..Time.zone.parse("2021-10-29 11:00")),
      ]
      expect(described_class.calculate_free_times(plage_ouverture, range)).to eq(expected_ranges)
    end

    it "don't returns past time" do
      friday = Time.zone.parse("20211112 20:00")
      travel_to(friday)
      starts_at = friday - 1.week
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent,
                                                recurrence: Montrose.every(:week, starts: starts_at.to_date - 1.day, day: [5]))
      range = Date.new(2021, 11, 12)..Date.new(2021, 11, 19)

      expected_ranges = [(Time.zone.parse("2021-11-19 9:00")..Time.zone.parse("2021-11-19 11:00"))]
      expect(described_class.calculate_free_times(plage_ouverture, range)).to eq(expected_ranges)
    end

    it "don't look at cancelled RDV" do
      friday = Time.zone.parse("20211112 20:00")
      travel_to(friday)
      starts_at = friday - 1.week
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent,
                                                recurrence: Montrose.every(:week, starts: starts_at.to_date - 1.day, day: [5]))
      create(:rdv, :excused, motif: motif, starts_at: Time.zone.parse("20211112 10:00"), agents: [agent])
      range = Date.new(2021, 11, 12)..Date.new(2021, 11, 19)

      expected_ranges = [(Time.zone.parse("2021-11-19 9:00")..Time.zone.parse("2021-11-19 11:00"))]
      expect(described_class.calculate_free_times(plage_ouverture, range)).to eq(expected_ranges)
    end

    it "return range without only range of multi RDV on same range with same duration" do
      starts_at = Time.zone.parse("20211027 9:00")
      ends_at = Time.zone.parse("20211027 11:00")
      create(:rdv, starts_at: starts_at + 45.minutes, agents: [agent])
      prev_rdv = create(:rdv, starts_at: starts_at - 30.minutes, agents: [agent])
      rdv = create(:rdv, starts_at: starts_at + 45.minutes, agents: [agent])
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent)
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)

      expected_ranges = [prev_rdv.ends_at..rdv.starts_at, rdv.ends_at..ends_at]
      expect(described_class.calculate_free_times(plage_ouverture, range)).to eq(expected_ranges)
    end

    it "return range without only range of longer overlapped RDV on same range with same duration" do
      starts_at = Time.zone.parse("20211027 9:00")
      ends_at = Time.zone.parse("20211027 11:00")
      create(:rdv, motif: create(:motif, organisation: organisation, default_duration_in_min: 30), starts_at: starts_at + 45.minutes, agents: [agent])
      prev_rdv = create(:rdv, starts_at: starts_at - 30.minutes, agents: [agent])
      rdv = create(:rdv, motif: create(:motif, organisation: organisation, default_duration_in_min: 30), starts_at: starts_at + 45.minutes, agents: [agent])
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent)
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)

      expected_ranges = [prev_rdv.ends_at..rdv.starts_at, rdv.ends_at..ends_at]
      expect(described_class.calculate_free_times(plage_ouverture, range)).to eq(expected_ranges)
    end
  end

  describe "#split_range_recursively" do
    it "return empty free times with an absence over range" do
      absence = build(:absence, first_day: Date.new(2021, 11, 26), start_time: Tod::TimeOfDay.new(8), end_time: Tod::TimeOfDay.new(12))
      range = Time.zone.parse("20211126 9:00")..Time.zone.parse("20211126 11:00")
      busy_times = [SlotBuilder::BusyTime.new(absence)]
      expect(described_class.split_range_recursively(range, busy_times)).to eq([])
    end
  end

  describe "#slots_for" do
    it "returns empty with empty free times" do
      motif = build(:motif)
      expect(described_class.slots_for({}, motif)).to eq([])
    end

    it "calls calculate_slots for plage_ouverture's free_time and motif" do
      motif = build(:motif)
      plage_ouverture = build(:plage_ouverture, motifs: [motif], first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
      free_times = [Time.zone.parse("20211027 9:00")..Time.zone.parse("20211027 11:00")]
      plage_ouverture_free_times = { plage_ouverture => free_times }

      allow(described_class).to receive(:calculate_slots).with(free_times.first, motif, plage_ouverture).and_return([])
      described_class.slots_for(plage_ouverture_free_times, motif)
    end
  end

  describe "#calculate_slots" do
    it "returns empty when free_time too short" do
      motif = build(:motif, default_duration_in_min: 30)
      plage_ouverture = build(:plage_ouverture, motifs: [motif], first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
      free_time = Time.zone.parse("20211027 9:00")..Time.zone.parse("20211027 9:15")
      expect(described_class.calculate_slots(free_time, motif, plage_ouverture)).to eq([])
    end

    it "returns slot that match with free time" do
      motif = build(:motif, default_duration_in_min: 30)
      plage_ouverture = build(:plage_ouverture, motifs: [motif], first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
      free_time = Time.zone.parse("20211027 9:00")..Time.zone.parse("20211027 9:45")

      slots = described_class.calculate_slots(free_time, motif, plage_ouverture) { |s| Creneau.new(starts_at: s) }
      expect(slots.map(&:starts_at).map(&:hour)).to eq([9])
    end
  end

  describe "#ranges_for" do
    context "without recurrence" do
      it "return empty when po is out of range" do
        plage_ouverture = build(:plage_ouverture, first_day: friday, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
        range = (friday + 3.days)..(friday + 10.days)
        expect(described_class.ranges_for(plage_ouverture, range)).to eq([])
      end

      it "return occurrence of po when is in range" do
        plage_ouverture = build(:plage_ouverture, first_day: friday + 4.days, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
        range = (friday + 3.days)..(friday + 10.days)
        expect(described_class.ranges_for(plage_ouverture, range)).to eq([Time.zone.parse("20210504 9:00")..Time.zone.parse("20210504 11:00")])
      end

      it "return occurrence minus already past time of today of po when is in range starting today" do
        friday = Time.zone.parse("20210430 12:00")
        travel_to(friday)
        plage_ouverture = build(:plage_ouverture, first_day: friday, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
        range = friday..(friday + 10.days)
        expect(described_class.ranges_for(plage_ouverture, range)).to eq([])
      end
    end

    context "with recurrence" do
      it "return empty when po and it occurrence is out of range" do
        plage_ouverture = build(:plage_ouverture, first_day: friday + 14.days, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11),
                                                  recurrence: Montrose.every(:week, starts: friday + 14.days))
        range = (friday + 3.days)..(friday + 10.days)
        expect(described_class.ranges_for(plage_ouverture, range)).to eq([])
      end

      it "return occurrence of po that in range" do
        plage_ouverture = build(:plage_ouverture, first_day: friday - 14.days, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11),
                                                  recurrence: Montrose.every(:week, starts: friday - 14.days))
        range = (friday + 3.days)..(friday + 10.days)
        expect(described_class.ranges_for(plage_ouverture, range)).to eq([(Time.zone.parse("20210507 9:00")..Time.zone.parse("20210507 11:00"))])
      end
    end
  end
end
