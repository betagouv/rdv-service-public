# frozen_string_literal: true

describe SlotBuilder, type: :service do
  let(:today) { Time.zone.parse("20210430 8:00") }
  let(:organisation) { create(:organisation) }
  let(:lieu) { create(:lieu, organisation: organisation) }

  before do
    travel_to(today)
  end

  # Recette
  describe "#available_slots" do
    let(:motif) { create(:motif, default_duration_in_min: 60, organisation: organisation) }
    let(:first_day) { Date.new(2021, 5, 3) }
    let(:date_range) { first_day..Date.new(2021, 5, 8) }
    let(:off_days) { [] }

    it "returns 2 slots with a basic context" do
      create(:plage_ouverture, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes, lieu: lieu)
      slots = described_class.available_slots(motif, lieu, date_range, off_days)
      expect(slots.map(&:starts_at).map(&:hour)).to eq([9, 10])
    end

    it "return Crenaux object" do
      create(:plage_ouverture, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes, lieu: lieu)
      slots = described_class.available_slots(motif, lieu, date_range, off_days)
      expect(slots.map(&:class).map(&:to_s).uniq).to eq(["Creneau"])
    end
  end

  describe "#plage_ouvertures_for" do
    let(:motif) { create(:motif, default_duration_in_min: 60, organisation: organisation) }
    let(:first_day) { Date.new(2021, 5, 3) }
    let(:date_range) { first_day..Date.new(2021, 5, 8) }

    it "return empty without plage_ouverture" do
      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range)

      expect(plage_ouvertures).to eq([])
    end

    it "return plage_ouverture that match" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range)

      expect(plage_ouvertures).to eq([matching_po])
    end

    it "returns all plage_ouverture for the range" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      other_matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range)

      expect(plage_ouvertures).to eq([matching_po, other_matching_po])
    end

    it "returns only without reccurrence PO where first_day is in range" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day + 1.month, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range)

      expect(plage_ouvertures).to eq([matching_po])
    end

    it "returns only same lieu PO" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      create(:plage_ouverture, lieu: create(:lieu), motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range)

      expect(plage_ouvertures).to eq([matching_po])
    end

    it "returns only same motif PO" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      create(:plage_ouverture, lieu: lieu, motifs: [create(:motif, organisation: organisation)], first_day: first_day, start_time: Tod::TimeOfDay.new(9),
                               end_time: Tod::TimeOfDay.new(11))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range)

      expect(plage_ouvertures).to eq([matching_po])
    end

    it "returns only not_expired PO" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: today - 1.day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range)

      expect(plage_ouvertures).to eq([matching_po])
    end

    it "returns PO with recurrences that always running" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      recurring_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day - 1.day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11),
                                              recurrence: Montrose.every(:week, starts: first_day - 1.day))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range)

      expect(plage_ouvertures.sort).to eq([matching_po, recurring_po].sort)
    end

    it "returns without recurrence PO that start in range" do
      matching_po = create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: first_day - 1.day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range)

      expect(plage_ouvertures).to eq([matching_po])
    end

    it "returns filtered PO on agent_ids given" do
      other_agent = create(:agent, organisations: [organisation])
      agent = create(:agent, organisations: [organisation])
      matching_po = create(:plage_ouverture, agent_id: other_agent.id, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9),
                                             end_time: Tod::TimeOfDay.new(11) + 20.minutes)
      create(:plage_ouverture, agent_id: agent.id, lieu: lieu, motifs: [motif], first_day: first_day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

      plage_ouvertures = described_class.plage_ouvertures_for(motif, lieu, date_range, agent_ids: [other_agent.id])

      expect(plage_ouvertures).to eq([matching_po])
    end
  end

  describe "#free_times_from" do
    it "return an empty hash without plage_ouvertures" do
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)
      expect(described_class.free_times_from([], range, [])).to eq({})
    end

    it "calls calculate_free_times for given plage_ouvertures" do
      plage_ouverture = build(:plage_ouverture)
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)
      expect(described_class).to receive(:calculate_free_times).with(plage_ouverture, range, [])
      described_class.free_times_from([plage_ouverture], range, [])
    end
  end

  describe "#calculate_free_times" do
    let(:motif) { create(:motif, default_duration_in_min: 60, organisation: organisation) }
    let(:agent) { create(:agent, organisations: [organisation]) }

    it "return one free time from plage ouverture date range" do
      plage_ouverture = build(:plage_ouverture, first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)
      expect(described_class.calculate_free_times(plage_ouverture, range, [])).to eq([Time.zone.parse("20211027 9:00")..Time.zone.parse("20211027 11:00")])
    end

    it "return plage ouverture slot minus rdv duration" do
      starts_at = Time.zone.parse("20211027 9:00")
      ends_at = Time.zone.parse("20211027 11:00")
      rdv = create(:rdv, motif: motif, starts_at: starts_at, agents: [agent])
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent, motifs: [motif])
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)

      expected_ranges = [rdv.ends_at..ends_at]
      expect(described_class.calculate_free_times(plage_ouverture, range, [])).to eq(expected_ranges)
    end

    it "return plage ouverture slot minus RDV duration that overlap po when RDV starts before PO" do
      starts_at = Time.zone.parse("20211027 9:00")
      ends_at = Time.zone.parse("20211027 11:00")
      rdv = create(:rdv, motif: motif, starts_at: starts_at - 30.minutes, agents: [agent])
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent)
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)

      expected_ranges = [rdv.ends_at..ends_at]
      expect(described_class.calculate_free_times(plage_ouverture, range, [])).to eq(expected_ranges)
    end

    it "return plage ouverture slots minus 2 RDV duration that overlap po" do
      starts_at = Time.zone.parse("20211027 9:00")
      ends_at = Time.zone.parse("20211027 11:00")
      rdv = create(:rdv, motif: motif, starts_at: starts_at - 30.minutes, agents: [agent])
      other_rdv = create(:rdv, motif: motif, starts_at: starts_at + 45.minutes, agents: [agent])
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent)
      range = Date.new(2021, 10, 26)..Date.new(2021, 10, 29)

      expected_ranges = [rdv.ends_at..other_rdv.starts_at, other_rdv.ends_at..ends_at]
      expect(described_class.calculate_free_times(plage_ouverture, range, [])).to eq(expected_ranges)
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
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent)
      range = Date.new(2021, 10, 25)..Date.new(2021, 10, 30)

      expected_ranges = [e9h30..s9h45, e10h45..ends_at]
      expect(described_class.calculate_free_times(plage_ouverture, range, [])).to eq(expected_ranges)
    end

    it "returns plage ouverture's 3 occurrences of range" do
      starts_at = Time.zone.parse("20211026 9:00")
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent,
                                                recurrence: Montrose.every(:week, starts: starts_at.to_date - 1.day, day: [1, 2, 4, 5]))
      range = Date.new(2021, 10, 25)..Date.new(2021, 10, 30)

      expected_ranges = [
        (Time.zone.parse("2021-10-26 9:00")..Time.zone.parse("2021-10-26 11:00")),
        (Time.zone.parse("2021-10-28 9:00")..Time.zone.parse("2021-10-28 11:00")),
        (Time.zone.parse("2021-10-29 9:00")..Time.zone.parse("2021-10-29 11:00"))
      ]
      expect(described_class.calculate_free_times(plage_ouverture, range, [])).to eq(expected_ranges)
    end

    it "don't returns past time" do
      today = Time.zone.parse("20211112 20:00")
      travel_to(today)
      starts_at = today - 1.week
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent,
                                                recurrence: Montrose.every(:week, starts: starts_at.to_date - 1.day, day: [5]))
      range = Date.new(2021, 11, 12)..Date.new(2021, 11, 19)

      expected_ranges = [(Time.zone.parse("2021-11-19 9:00")..Time.zone.parse("2021-11-19 11:00"))]
      expect(described_class.calculate_free_times(plage_ouverture, range, [])).to eq(expected_ranges)
    end

    it "don't look at cancelled RDV" do
      today = Time.zone.parse("20211112 20:00")
      travel_to(today)
      starts_at = today - 1.week
      plage_ouverture = build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent,
                                                recurrence: Montrose.every(:week, starts: starts_at.to_date - 1.day, day: [5]))
      create(:rdv, :excused, motif: motif, starts_at: Time.zone.parse("20211112 10:00"), agents: [agent])
      range = Date.new(2021, 11, 12)..Date.new(2021, 11, 19)

      expected_ranges = [(Time.zone.parse("2021-11-19 9:00")..Time.zone.parse("2021-11-19 11:00"))]
      expect(described_class.calculate_free_times(plage_ouverture, range, [])).to eq(expected_ranges)
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

      allow(described_class).to receive(:calculate_slots).with(free_times.first, motif).and_return([])
      described_class.slots_for(plage_ouverture_free_times, motif)
    end
  end

  describe "#calculate_slots" do
    it "returns empty when free_time too short" do
      motif = build(:motif, default_duration_in_min: 30)
      free_time = Time.zone.parse("20211027 9:00")..Time.zone.parse("20211027 9:15")
      expect(described_class.calculate_slots(free_time, motif)).to eq([])
    end

    it "returns slot that match with free time" do
      motif = build(:motif, default_duration_in_min: 30)
      free_time = Time.zone.parse("20211027 9:00")..Time.zone.parse("20211027 9:45")

      slots = described_class.calculate_slots(free_time, motif) { |s| Creneau.new(starts_at: s) }
      expect(slots.map(&:starts_at).map(&:hour)).to eq([9])
    end
  end

  #
  # RECETTE
  #

  #
  # avec
  # - une absence le 10 décembre 2020 de 9 h 45 à 10 h 15
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 10 décembre 2020 à 10 h 15
  # - du 10 décembre 2020 à 10 h 45

  #
  # avec
  # - une absence du 10 décembre 2020 à 9 h 45 qui fini le 11 décembre 2020 à 6 h 30
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 11 décembre 2020 à 9 h
  # - du 11 décembre 2020 à 9 h 30
  # - du 11 décembre 2020 à 10 h
  # - du 11 décembre 2020 à 10 h 30

  #
  # avec
  # - une absence du 10 décembre 2020 à 9 h 45 qui fini le 11 décembre 2020 à 9 h 05
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 11 décembre 2020 à 9 h 05
  # - du 11 décembre 2020 à 9 h 35
  # - du 11 décembre 2020 à 10 h 05

  #
  # avec
  # - une absence du jeudi 3 décembre 2020 à 9 h 45 qui fini le jeudi 3 décembre 2020 à 10 h 15 qui se répète toutes les semaines
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 10 décembre 2020 à 10 h 15
  # - du 10 décembre 2020 à 10 h 45

  #
  # avec
  # - un RDV le jeudi 10 décembre 2020 à 9 h 30 qui fini le jeudi 3 décembre 2020 à 10 h
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 10 décembre 2020 à 10 h
  # - du 10 décembre 2020 à 10 h 30

  #
  # avec
  # - un RDV le jeudi 10 décembre 2020 à 9 h 30 qui fini le jeudi 3 décembre 2020 à 9 h 45
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 10 décembre 2020 à 9 h 45
  # - du 10 décembre 2020 à 10 h 15
  # - du 10 décembre 2020 à 10 h 45

  #
  # avec
  # - un RDV le jeudi 10 décembre 2020 à 9 h 30 qui fini le jeudi 3 décembre 2020 à 10 h 15
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 10 décembre 2020 à 10 h 15
  # - du 10 décembre 2020 à 10 h 45

  #
  # avec
  # - un RDV ANNULÉ le jeudi 10 décembre 2020 à 9 h 30 qui fini le jeudi 3 décembre 2020 à 10 h
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 10 décembre 2020 à 9 h 30
  # - du 10 décembre 2020 à 10 h
  # - du 10 décembre 2020 à 10 h 30

  # avec
  # - un jour fériée
  # - aujourd'hui étant le 1 janvier 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être vide
  # -- NOTE YAF: en même temps, s'il n'y a pas de plage d'ouverture sur ce jour là...

  # avec
  # - un RDV le jeudi 16 décembre 2020 à 10 h qui fini le jeudi 16 décembre 2020 à 10 h 30
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 16 décembre 2020 à 9 h
  #   - qui fini à 11 h
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 9 h
  # - du 16 décembre 2020 à 9 h 30
  # - du 16 décembre 2020 à 10 h

  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 10 h
  #   - qui fini à 12 h
  #   - pour un autre agent
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 9 h
  # - du 16 décembre 2020 à 9 h 30
  # - du 16 décembre 2020 à 10 h
  # - du 16 décembre 2020 à 10 h 30
  # - du 16 décembre 2020 à 11 h
  # - du 16 décembre 2020 à 11 h 30

  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent A
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 10 h
  #   - qui fini à 12 h
  #   - pour un autre agent B
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020 POUR les agents
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 9 h pour l'agent A
  # - du 16 décembre 2020 à 9 h 30 pour l'agent A
  # - du 16 décembre 2020 à 10 h pour l'agent A
  # - du 16 décembre 2020 à 10 h pour l'agent B
  # - du 16 décembre 2020 à 10 h 30 pour l'agent A
  # - du 16 décembre 2020 à 10 h 30 pour l'agent B
  # - du 16 décembre 2020 à 11 h pour l'agent B
  # - du 16 décembre 2020 à 11 h 30 pour l'agent B

  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent A
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 10 h
  #   - qui fini à 12 h
  #   - pour un autre agent B
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020 POUR l'agent B
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 10 h pour l'agent B
  # - du 16 décembre 2020 à 10 h 30 pour l'agent B
  # - du 16 décembre 2020 à 11 h pour l'agent B
  # - du 16 décembre 2020 à 11 h 30 pour l'agent B

  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent A
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 10 h
  #   - qui fini à 12 h
  #   - pour un autre agent B
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020 POUR aucun agent
  #
  # Le résultat doit être vide

  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif nomé A sur place d'une durée de 30 minutes
  # - un motif nomé A à domicile d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - pour les deux motif nomé A
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020 un agent pour un agent filtré sur les motifs à domicile
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 10 h pour le motif A à domicile
  # - du 16 décembre 2020 à 10 h 30 pour le motif A à domicile
  # - du 16 décembre 2020 à 11 h pour le motif A à domicile
  # - du 16 décembre 2020 à 11 h 30 pour le motif A à domicile

  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'un service A nomé MonMotif
  # - un motif d'un service B nomé MonMotif
  # - une plage d'ouverture
  #   - pour le motif du service A
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  # - une plage d'ouverture
  #   - pour le motif du service B
  #   - qui démarre le 10 décembre 2020 à 14 h
  #   - qui fini à 14 h 35
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020 pour le service A
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 9 h pour le motif du service A
  # - du 16 décembre 2020 à 9 h 30 pour le motif du service A
  # - du 16 décembre 2020 à 10 h pour le motif du service A
  # - du 16 décembre 2020 à 10 h 30 pour le motif du service A
  # - du 16 décembre 2020 à 11 h pour le motif du service A
  # - du 16 décembre 2020 à 11 h 30 pour le motif du service A ???? TRÈS BIZARRE !
  # - du 16 décembre 2020 à 14 h pour le motif du service B

  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif avec un min booking_delay de 30 minutes
  # - une plage d'ouverture
  #   - pour le motif
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  # - la date du jour au 10 décembre 2020 à 9 h 15
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 10 h pour le motif du service A
  # - du 16 décembre 2020 à 10 h 30 pour le motif du service A
  #
  # Pourquoi pas le 9 h 30 ?

  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif avec un max booking_delay de 45 minutes
  # - une plage d'ouverture
  #   - pour le motif
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  # - la date du jour au 10 décembre 2020 à 9 h 15
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 10 h pour le motif du service A
  #
  # Pourquoi pas le 9 h 30 ?

  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif
  # - une plage d'ouverture
  #   - pour le motif
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  # - la date du jour au 10 décembre 2020 à 10 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 10 h 30 pour le motif du service A ?
  #
end
