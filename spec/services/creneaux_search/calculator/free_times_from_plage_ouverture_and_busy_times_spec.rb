RSpec.describe CreneauxSearch::Calculator::FreeTimesFromPlageOuvertureAndBusyTimes do
  subject(:free_times) { described_class.new(range, plage_ouverture, work_on_off_days:).perform }

  let(:plage_ouverture) { build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent) }
  let(:friday) { Time.zone.parse("20210430 8:00") }
  let(:range) { Date.new(2021, 10, 26)...Date.new(2021, 10, 29) }
  let(:work_on_off_days) { false }

  let(:motif) { create(:motif, default_duration_in_min: 60, organisation: organisation) }
  let(:agent) { create(:agent, organisations: [organisation]) }
  let(:organisation) { create(:organisation) }
  let(:starts_at) { Time.zone.parse("20211027 9:00") }

  before { travel_to(friday) }

  it "return plage ouverture slot minus rdv duration" do
    ends_at = Time.zone.parse("20211027 11:00")
    rdv = create(:rdv, motif: motif, starts_at: starts_at, agents: [agent], organisation:)

    expect(free_times).to eq([rdv.ends_at...ends_at])
  end

  it "return plage ouverture slot minus RDV duration that overlap po when RDV starts before PO" do
    ends_at = Time.zone.parse("20211027 11:00")
    rdv = create(:rdv, motif: motif, starts_at: starts_at - 30.minutes, agents: [agent], organisation:)

    expected_ranges = [rdv.ends_at...ends_at]
    expect(free_times).to eq(expected_ranges)
  end

  context "with 2 rdvs" do
    let(:plage_ouverture) { build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent) }
    let(:range) { Date.new(2021, 10, 26)...Date.new(2021, 10, 29) }

    it "return plage ouverture slots minus 2 RDV duration" do
      ends_at = Time.zone.parse("20211027 11:00")
      rdv = create(:rdv, motif: motif, starts_at: starts_at - 30.minutes, agents: [agent], organisation:)
      other_rdv = create(:rdv, motif: motif, starts_at: starts_at + 45.minutes, agents: [agent], organisation:)

      expect(free_times).to eq([rdv.ends_at...other_rdv.starts_at, other_rdv.ends_at...ends_at])
    end
  end

  context "with 2 absences" do
    let(:range) { Date.new(2021, 10, 25)...Date.new(2021, 10, 30) }
    let(:plage_ouverture) do
      create(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent, organisation: organisation)
    end

    it "return plage ouverture slots minus 2 Absences duration that overlap po" do
      ends_at = Time.zone.parse("20211027 11:00")

      s8h30 = Time.zone.parse("20211027 8:30")
      e9h30 = Time.zone.parse("20211027 9:30")
      s9h45 = Time.zone.parse("20211027 9:45")
      e10h45 = Time.zone.parse("20211027 10:45")

      create(:absence, first_day: s8h30.to_date, start_time: Tod::TimeOfDay.new(s8h30.hour, s8h30.min), end_day: e9h30.to_date, end_time: Tod::TimeOfDay.new(e9h30.hour, e9h30.min), agent: agent)
      create(:absence, first_day: s9h45.to_date, start_time: Tod::TimeOfDay.new(s9h45.hour, s9h45.min), end_day: e10h45.to_date, end_time: Tod::TimeOfDay.new(e10h45.hour, e10h45.min), agent: agent)

      expect(free_times).to eq([e9h30...s9h45, e10h45...ends_at])
    end
  end

  context "with 2 external events" do
    let(:agent) { create(:agent, :with_caldav_config, organisations: [organisation]) }
    let(:range) { Date.new(2021, 10, 25)...Date.new(2021, 10, 30) }
    let(:plage_ouverture) { create(:plage_ouverture, first_day: Date.parse("2021-10-27"), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent:, organisation:) }

    it "return plage ouverture slots minus 2 ExternalCalendarEvent duration that overlap po" do
      # Plage le 27 oct de 9h à 11h

      # Événements externes le même jour de 8h30 à 9h30, puis de 9h45 à 10h45
      s8h30 = Time.zone.parse("2021-10-27 08:30")
      e9h30 = Time.zone.parse("2021-10-27 09:30")
      s9h45 = Time.zone.parse("2021-10-27 09:45")
      e10h45 = Time.zone.parse("2021-10-27 10:45")
      ExternalCalendarEvent.create!(agent:, starts_at: s8h30, ends_at: e9h30, url: "abcde1")
      ExternalCalendarEvent.create!(agent:, starts_at: s9h45, ends_at: e10h45, url: "abcde2")

      expected_ranges = [e9h30...s9h45, e10h45...plage_ouverture.ends_at]
      expect(free_times).to eq(expected_ranges)
    end
  end

  context "with recurring external calendar events" do
    let(:range) { Date.new(2021, 10, 25)...Date.new(2021, 10, 30) }
    let(:agent) { create(:agent, :with_caldav_config, organisations: [organisation]) }
    let(:plage_ouverture) { create(:plage_ouverture, first_day: Date.parse("2021-10-27"), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent:, organisation:) }

    it "handles recurring external calendar events" do
      # Plage le mercredi 27 oct 2021 de 9h à 11h

      # Recurs every week day from 9h45 to 10h00, so in the middle of the plâââge
      create(:external_calendar_event, :recurring_on_weekdays, agent:)

      at_9h00 = Time.zone.parse("2021-10-27 09:00")
      at_9h45 = Time.zone.parse("2021-10-27 09:45")
      at_10h00 = Time.zone.parse("2021-10-27 10:00")

      expected_ranges = [at_9h00...at_9h45, at_10h00...plage_ouverture.ends_at]
      expect(free_times).to eq(expected_ranges)
    end
  end

  context "with reccurrent plage_ouverture" do
    let(:starts_at) { Time.zone.parse("20211026 9:00") }
    let(:range) { Date.new(2021, 10, 25)...Date.new(2021, 10, 30) }
    let(:plage_ouverture) do
      build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent,
                              recurrence: Montrose.every(:week, starts: starts_at.to_date - 1.day, day: [1, 2, 4, 5], interval: 1))
    end

    it "returns plage ouverture's 3 occurrences of range" do
      expected_ranges = [
        (Time.zone.parse("2021-10-26 9:00")...Time.zone.parse("2021-10-26 11:00")),
        (Time.zone.parse("2021-10-28 9:00")...Time.zone.parse("2021-10-28 11:00")),
        (Time.zone.parse("2021-10-29 9:00")...Time.zone.parse("2021-10-29 11:00")),
      ]
      expect(free_times).to eq(expected_ranges)
    end
  end

  context "when part of the range is in the past" do
    let(:range) { Date.new(2021, 11, 12)...Date.new(2021, 11, 19) }
    let(:plage_ouverture) do
      build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent,
                              recurrence: Montrose.every(:week, starts: starts_at.to_date - 1.day, day: [5], interval: 1))
    end
    let(:starts_at) { friday - 1.week }

    it "don't returns past time" do
      friday = Time.zone.parse("20211112 20:00")
      travel_to(friday)

      expect(free_times).to eq([(Time.zone.parse("2021-11-19 9:00")...Time.zone.parse("2021-11-19 11:00"))])
    end
  end

  context "with a cancelled rdv" do
    let(:starts_at) { friday - 1.week }
    let(:plage_ouverture) do
      build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent,
                              recurrence: Montrose.every(:week, starts: starts_at.to_date - 1.day, day: [5], interval: 1))
    end
    let(:range) { Date.new(2021, 11, 12)...Date.new(2021, 11, 19) }

    it "don't look at cancelled RDV" do
      friday = Time.zone.parse("20211112 20:00")
      travel_to(friday)
      create(:rdv, :excused, motif: motif, starts_at: Time.zone.parse("20211112 10:00"), agents: [agent], organisation:)

      expected_ranges = [(Time.zone.parse("2021-11-19 9:00")...Time.zone.parse("2021-11-19 11:00"))]
      expect(free_times).to eq(expected_ranges)
    end
  end

  context "with multiple rdvs" do
    let(:range) { Date.new(2021, 10, 26)...Date.new(2021, 10, 29) }
    let(:starts_at) { Time.zone.parse("20211027 9:00") }
    let(:plage_ouverture) { build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent) }

    it "return range without only range of multi RDV on same range with same duration" do
      ends_at = Time.zone.parse("20211027 11:00")
      create(:rdv, starts_at: starts_at + 45.minutes, agents: [agent])
      prev_rdv = create(:rdv, starts_at: starts_at - 30.minutes, agents: [agent])
      rdv = create(:rdv, starts_at: starts_at + 45.minutes, agents: [agent])

      expected_ranges = [prev_rdv.ends_at...rdv.starts_at, rdv.ends_at...ends_at]
      expect(free_times).to eq(expected_ranges)
    end
  end

  context "with overlapping rdvs" do
    let(:starts_at) { Time.zone.parse("20211027 9:00") }
    let(:range) { Date.new(2021, 10, 26)...Date.new(2021, 10, 29) }
    let(:plage_ouverture) { build(:plage_ouverture, first_day: starts_at.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent) }

    it "return range without only range of longer overlapped RDV on same range with same duration" do
      ends_at = Time.zone.parse("20211027 11:00")
      create(:rdv, motif: create(:motif, organisation: organisation, default_duration_in_min: 30), starts_at: starts_at + 45.minutes, agents: [agent], organisation:)
      prev_rdv = create(:rdv, starts_at: starts_at - 30.minutes, agents: [agent], organisation:)
      rdv = create(:rdv, motif: create(:motif, organisation: organisation, default_duration_in_min: 30), starts_at: starts_at + 45.minutes, agents: [agent], organisation:)

      expected_ranges = [prev_rdv.ends_at...rdv.starts_at, rdv.ends_at...ends_at]
      expect(free_times).to eq(expected_ranges)
    end
  end

  it "truncates off days (jours féries) from the ranges" do
    xmas_week = Date.new(2024, 12, 23)..Date.new(2024, 12, 27)
    plage_ouverture = create(:plage_ouverture, :weekdays, first_day: Date.new(2024, 12, 23), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11))

    # Par défaut les jours fériés ne sont pas travaillés
    free_times = described_class.new(xmas_week, plage_ouverture, work_on_off_days: false).perform
    computed_dates = free_times.map(&:begin).map(&:to_date)

    expect(computed_dates).to eq(xmas_week.to_a - [Date.new(2024, 12, 25)])

    # Mais ils peuvent être activés avec un flag
    free_times = described_class.new(xmas_week, plage_ouverture, work_on_off_days: true).perform

    computed_dates = free_times.map(&:begin).map(&:to_date)
    expect(computed_dates).to eq(xmas_week.to_a)
  end

  describe "request to fetch rdvs" do
    let(:available_ranges) do
      [Time.zone.parse("2021-10-26 06:00:00")..Time.zone.parse("2021-10-29 10:00:00")]
    end

    # Décommentez ces tests si vous changez la requête pour vérifier qu'elle reste rapide.
    # Ce test est trop long pour être ajouté à la CI pour chaque build (il faut créer beaucoup de données), mais il est utile si l'index ou la requête change
    before do
      # Il faut créer un minimum de données pour que l'index soit utilisé (le query planner prend des décisions en fonction de la taille des tables et des indexes)
      100.times do |i|
        create(:rdv, starts_at: Time.zone.parse("20211027 9:00") + (i * 30.minutes), ends_at: Time.zone.parse("20211027 9:40") + (i * 30.minutes))
        create(:rdv, agents: [agent], starts_at: Time.zone.parse("20211027 9:00") + (i * 30.minutes), ends_at: Time.zone.parse("20211027 9:40") + (i * 30.minutes))
      end
    end

    it "est optimisée pour utiliser l'index 'calculator_index'. Décommentez le test suivant si celui-ci échoue." do
      # Voir https://www.postgresql.org/docs/current/indexes-index-only-scans.html
      request = described_class.new(range, plage_ouverture, work_on_off_days: false).send(:optimized_rdv_request, available_ranges)
      expect(request.select(:calculator_rdv_starts_at, :calculator_rdv_ends_at).to_sql.squish).to eq <<~SQL.squish
        SELECT "agents_rdvs"."calculator_rdv_starts_at",
               "agents_rdvs"."calculator_rdv_ends_at"
        FROM "agents_rdvs"
        WHERE "agents_rdvs"."agent_id" = #{agent.id}
          AND "agents_rdvs"."calculator_rdv_not_cancelled_and_in_the_future" = TRUE
          AND (tsrange(calculator_rdv_starts_at, calculator_rdv_ends_at, '[)') && (tsmultirange(tsrange('2021-10-26 04:00:00', '2021-10-29 08:00:00', '[]'))))
      SQL
    end

    # TODO: depuis l'utilisation du tsmultirange, ce test ne passe plus. En fonction des performances qu'on obtient en production, ce n'est pas forcément un problème.
    # On pourrait voir si en production on a encore des index-only scan, et/ou utiliser un grand range plutôt qu'un multirange (mais ce n'est pas clair si le tradeoff est positif).
    # it "is optimized to use an index only scan" do
    #   # Voir https://www.postgresql.org/docs/current/indexes-index-only-scans.html
    #   request = described_class.new(range, plage_ouverture, work_on_off_days: false).send(:optimized_rdv_request, available_ranges)
    #   expect(request.select(:calculator_rdv_starts_at, :calculator_rdv_ends_at).explain.inspect).to include "Index Only Scan using calculator_index"
    # end
  end
end
