RSpec.describe CreneauxSearch::Calculator do
  subject(:available_slots) { described_class.available_slots(motif:, lieu:, date_range:) }

  let(:friday) { Time.zone.parse("20210430 8:00") }
  let(:organisation) { create(:organisation) }
  let(:lieu) { create(:lieu, organisation: organisation) }

  before { travel_to(friday) }

  describe "#available_slots" do
    let(:motif) { create(:motif, default_duration_in_min: 60, organisation: organisation) }
    let(:first_day) { Date.new(2021, 5, 3) }
    let(:date_range) { first_day..Date.new(2021, 5, 8) }

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
  end

  # Ces tests legacy appellent une méthode privée
  describe "#plage_ouvertures" do
    let(:motif) { create(:motif, default_duration_in_min: 60, organisation: organisation) }
    let(:first_day) { Date.new(2021, 5, 3) }
    let(:date_range) { first_day..Date.new(2021, 5, 8) }

    it "returns all plage_ouverture for the range" do
      create(:plage_ouverture, lieu:, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      create(:plage_ouverture, lieu:, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

      expect(available_slots.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00", "10:00", "09:00", "10:00"])
    end

    it "returns only without recurrence PO where first_day is in range" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day + 1.month, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

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
                                              recurrence: Montrose.every(:week, starts: first_day - 1.day, interval: 1))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range, [])
      expect(plage_ouvertures).to contain_exactly(matching_po, recurring_po)
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

    it "excludes plage ouvertures for agents with a pending invitation" do
      agents = {
        normal: create(:agent, organisations: [organisation]),
        pending_invitation: create(
          :agent,
          organisations: [organisation],
          invitation_sent_at: first_day - 48.hours,
          invitation_accepted_at: nil,
          confirmed_at: nil
        ),
        intervenant: create(
          :agent, :intervenant,
          organisations: [organisation],
          confirmed_at: nil,
          invitation_sent_at: nil
        ),
        invited_accepted: create(
          :agent,
          organisations: [organisation],
          invitation_sent_at: first_day - 48.hours,
          invitation_accepted_at: first_day - 24.hours,
          confirmed_at: first_day - 24.hours
        ),
      }
      plage_ouvertures = agents.transform_values do |agent|
        create(
          :plage_ouverture,
          agent:,
          lieu: lieu, motifs: [motif],
          first_day: first_day,
          start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11)
        )
      end

      filtered_plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range, [])
      expect(filtered_plage_ouvertures).to include(plage_ouvertures[:normal], plage_ouvertures[:intervenant], plage_ouvertures[:invited_accepted])
      expect(filtered_plage_ouvertures).not_to include(plage_ouvertures[:pending_invitation])
    end
  end

  describe "#calculate_free_times" do
    let(:motif) { create(:motif, default_duration_in_min: 60, organisation: organisation) }
    let(:agent) { create(:agent, organisations: [organisation]) }

    it "return plage ouverture slot minus rdv duration" do
      starts_at = Time.zone.parse("20211027 9:00")
      ends_at = Time.zone.parse("20211027 11:00")
      rdv = create(:rdv, motif: motif, starts_at: starts_at, agents: [agent], organisation:)
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent, motifs: [motif])
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)

      expected_ranges = [rdv.ends_at..ends_at]
      expect(described_class.calculate_free_times(plage_ouverture, range, work_on_off_days: false)).to eq(expected_ranges)
    end

    it "return plage ouverture slot minus RDV duration that overlap po when RDV starts before PO" do
      starts_at = Time.zone.parse("20211027 9:00")
      ends_at = Time.zone.parse("20211027 11:00")
      rdv = create(:rdv, motif: motif, starts_at: starts_at - 30.minutes, agents: [agent], organisation:)
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent)
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)

      expected_ranges = [rdv.ends_at..ends_at]
      expect(described_class.calculate_free_times(plage_ouverture, range, work_on_off_days: false)).to eq(expected_ranges)
    end

    it "return plage ouverture slots minus 2 RDV duration that overlap po" do
      starts_at = Time.zone.parse("20211027 9:00")
      ends_at = Time.zone.parse("20211027 11:00")
      rdv = create(:rdv, motif: motif, starts_at: starts_at - 30.minutes, agents: [agent], organisation:)
      other_rdv = create(:rdv, motif: motif, starts_at: starts_at + 45.minutes, agents: [agent], organisation:)
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent)
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)

      expected_ranges = [rdv.ends_at..other_rdv.starts_at, other_rdv.ends_at..ends_at]
      expect(described_class.calculate_free_times(plage_ouverture, range, work_on_off_days: false)).to eq(expected_ranges)
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
      expect(described_class.calculate_free_times(plage_ouverture, range, work_on_off_days: false)).to eq(expected_ranges)
    end

    it "return plage ouverture slots minus 2 ExternalCalendarEvent duration that overlap po" do
      agent = create(:agent, :with_caldav_config, organisations: [organisation])

      # Plage le 27 oct de 9h à 11h
      plage_ouverture = create(:plage_ouverture, first_day: Date.parse("2021-10-27"), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent:, organisation:)

      # Événements externes le même jour de 8h30 à 9h30, puis de 9h45 à 10h45
      s8h30 = Time.zone.parse("2021-10-27 08:30")
      e9h30 = Time.zone.parse("2021-10-27 09:30")
      s9h45 = Time.zone.parse("2021-10-27 09:45")
      e10h45 = Time.zone.parse("2021-10-27 10:45")
      ExternalCalendarEvent.create!(agent:, starts_at: s8h30, ends_at: e9h30, url: "abcde1")
      ExternalCalendarEvent.create!(agent:, starts_at: s9h45, ends_at: e10h45, url: "abcde2")

      range = Date.new(2021, 10, 25)..Date.new(2021, 10, 30)

      expected_ranges = [e9h30..s9h45, e10h45..plage_ouverture.ends_at]
      expect(described_class.calculate_free_times(plage_ouverture, range, work_on_off_days: false)).to eq(expected_ranges)
    end

    it "handles recurring external calendar events" do
      agent = create(:agent, :with_caldav_config, organisations: [organisation])

      # Plage le mercredi 27 oct 2021 de 9h à 11h
      plage_ouverture = create(:plage_ouverture, first_day: Date.parse("2021-10-27"), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent:, organisation:)

      # Recurs every week day from 9h45 to 10h00, so in the middle of the plâââge
      create(:external_calendar_event, :recurring_on_weekdays, agent:)

      at_9h00 = Time.zone.parse("2021-10-27 09:00")
      at_9h45 = Time.zone.parse("2021-10-27 09:45")
      at_10h00 = Time.zone.parse("2021-10-27 10:00")

      expected_ranges = [at_9h00..at_9h45, at_10h00..plage_ouverture.ends_at]
      within_range = Date.new(2021, 10, 25)..Date.new(2021, 10, 30)
      expect(described_class.calculate_free_times(plage_ouverture, within_range, work_on_off_days: false)).to eq(expected_ranges)
    end

    it "returns plage ouverture's 3 occurrences of range" do
      starts_at = Time.zone.parse("20211026 9:00")
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent,
                                                recurrence: Montrose.every(:week, starts: starts_at.to_date - 1.day, day: [1, 2, 4, 5], interval: 1))
      range = Date.new(2021, 10, 25)..Date.new(2021, 10, 30)

      expected_ranges = [
        (Time.zone.parse("2021-10-26 9:00")..Time.zone.parse("2021-10-26 11:00")),
        (Time.zone.parse("2021-10-28 9:00")..Time.zone.parse("2021-10-28 11:00")),
        (Time.zone.parse("2021-10-29 9:00")..Time.zone.parse("2021-10-29 11:00")),
      ]
      expect(described_class.calculate_free_times(plage_ouverture, range, work_on_off_days: false)).to eq(expected_ranges)
    end

    it "don't returns past time" do
      friday = Time.zone.parse("20211112 20:00")
      travel_to(friday)
      starts_at = friday - 1.week
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent,
                                                recurrence: Montrose.every(:week, starts: starts_at.to_date - 1.day, day: [5], interval: 1))
      range = Date.new(2021, 11, 12)..Date.new(2021, 11, 19)

      expected_ranges = [(Time.zone.parse("2021-11-19 9:00")..Time.zone.parse("2021-11-19 11:00"))]
      expect(described_class.calculate_free_times(plage_ouverture, range, work_on_off_days: false)).to eq(expected_ranges)
    end

    it "don't look at cancelled RDV" do
      friday = Time.zone.parse("20211112 20:00")
      travel_to(friday)
      starts_at = friday - 1.week
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent,
                                                recurrence: Montrose.every(:week, starts: starts_at.to_date - 1.day, day: [5], interval: 1))
      create(:rdv, :excused, motif: motif, starts_at: Time.zone.parse("20211112 10:00"), agents: [agent], organisation:)
      range = Date.new(2021, 11, 12)..Date.new(2021, 11, 19)

      expected_ranges = [(Time.zone.parse("2021-11-19 9:00")..Time.zone.parse("2021-11-19 11:00"))]
      expect(described_class.calculate_free_times(plage_ouverture, range, work_on_off_days: false)).to eq(expected_ranges)
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
      expect(described_class.calculate_free_times(plage_ouverture, range, work_on_off_days: false)).to eq(expected_ranges)
    end

    it "return range without only range of longer overlapped RDV on same range with same duration" do
      starts_at = Time.zone.parse("20211027 9:00")
      ends_at = Time.zone.parse("20211027 11:00")
      create(:rdv, motif: create(:motif, organisation: organisation, default_duration_in_min: 30), starts_at: starts_at + 45.minutes, agents: [agent], organisation:)
      prev_rdv = create(:rdv, starts_at: starts_at - 30.minutes, agents: [agent], organisation:)
      rdv = create(:rdv, motif: create(:motif, organisation: organisation, default_duration_in_min: 30), starts_at: starts_at + 45.minutes, agents: [agent], organisation:)
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent)
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)

      expected_ranges = [prev_rdv.ends_at..rdv.starts_at, rdv.ends_at..ends_at]
      expect(described_class.calculate_free_times(plage_ouverture, range, work_on_off_days: false)).to eq(expected_ranges)
    end

    it "truncates off days (jours féries) from the ranges" do
      xmas_week = Date.new(2024, 12, 23)..Date.new(2024, 12, 27)
      plage_ouverture = create(:plage_ouverture, :weekdays, first_day: Date.new(2024, 12, 23), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

      # Par défaut les jours fériés ne sont pas travaillés
      computed_dates = described_class.calculate_free_times(plage_ouverture, xmas_week, work_on_off_days: false).map(&:begin).map(&:to_date)
      expect(computed_dates).to eq(xmas_week.to_a - [Date.new(2024, 12, 25)])

      # Mais ils peuvent être activés avec un flag
      computed_dates = described_class.calculate_free_times(plage_ouverture, xmas_week, work_on_off_days: true).map(&:begin).map(&:to_date)
      expect(computed_dates).to eq(xmas_week.to_a)
    end
  end

  describe "#split_range_recursively" do
    it "return empty free times with an absence over range" do
      absence = build(:absence, first_day: Date.new(2021, 11, 26), start_time: Tod::TimeOfDay.new(8), end_time: Tod::TimeOfDay.new(12))
      range = Time.zone.parse("20211126 9:00")..Time.zone.parse("20211126 11:00")
      busy_times = [CreneauxSearch::Calculator::BusyTime.new(absence.starts_at, absence.ends_at)]
      expect(described_class.split_range_recursively(range, busy_times)).to eq([])
    end
  end

  describe "#calculate_slots" do
    it "returns empty when free_time too short" do
      motif = build(:motif, default_duration_in_min: 30)
      plage_ouverture = build(:plage_ouverture, motifs: [motif], first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
      free_time = Time.zone.parse("20211027 9:00")..Time.zone.parse("20211027 9:15")
      expect(described_class.calculate_slots(free_time, motif, plage_ouverture)).to eq([])
    end

    it "returns slots that fit" do
      motif = build(:motif, default_duration_in_min: 30)
      plage_ouverture = build(:plage_ouverture, motifs: [motif], first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
      free_time = Time.zone.parse("20211027 9:00")..Time.zone.parse("20211027 10:15")

      slots = described_class.calculate_slots(free_time, motif, plage_ouverture)
      expect(slots.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00", "09:30"])
      expect(slots.map(&:duration_in_min)).to eq([30, 30])
    end

    it "returns slots that fit when passed an overriden duration_in_min" do
      motif = build(:motif, default_duration_in_min: 30)
      plage_ouverture = build(:plage_ouverture, motifs: [motif], first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
      free_time = Time.zone.parse("20211027 9:00")..Time.zone.parse("20211027 10:15")

      slots = described_class.calculate_slots(free_time, motif, plage_ouverture, duration_in_min: 20)
      expect(slots.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00", "09:20", "09:40"])
      expect(slots.map(&:duration_in_min)).to eq([20, 20, 20])
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
                                                  recurrence: Montrose.every(:week, starts: friday + 14.days, interval: 1))
        range = (friday + 3.days)..(friday + 10.days)
        expect(described_class.ranges_for(plage_ouverture, range)).to eq([])
      end

      it "return occurrence of po that in range" do
        plage_ouverture = build(:plage_ouverture, first_day: friday - 14.days, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11),
                                                  recurrence: Montrose.every(:week, starts: friday - 14.days, interval: 1))
        range = (friday + 3.days)..(friday + 10.days)
        expect(described_class.ranges_for(plage_ouverture, range)).to eq([(Time.zone.parse("20210507 9:00")..Time.zone.parse("20210507 11:00"))])
      end
    end
  end
end
