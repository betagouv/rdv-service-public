RSpec.describe CreneauxSearch::Calculator::BusyTimePreloader, type: :service do
  # TODO: déplacer ces specs
  subject(:busy_times) do
    described_class.start_loading_busy_times_for(range, agent, work_on_off_days: false).busy_times
  end

  let(:monday) { Time.zone.parse("20211025 10:00") }
  let(:range) { Time.zone.parse("2021-10-26 8:00")..Time.zone.parse("2021-10-29 12:00") }
  let(:agent) { create(:agent) }

  before { travel_to(monday) }

  context "with a RDV" do
    it "returns a BusyTime with the correct attributes" do
      create(:rdv, agents: [agent], starts_at: Time.zone.parse("20211027 9:00"), ends_at: Time.zone.parse("20211027 9:40"))

      busy_time = busy_times.first
      expect(busy_time).to have_attributes(
        starts_at: Time.zone.parse("20211027 9:00"),
        ends_at: Time.zone.parse("20211027 9:40")
      )
    end
  end

  context "with an absence without recurrence" do
    it "returns BusyTime starts_at as absence first_day and start_time" do
      create(:absence, agent: agent, first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9))
      expect(busy_times.first.starts_at).to eq(Time.zone.parse("20211027 9:00"))
    end

    it "returns BusyTime ends_at as absence first_day and end_time when end_day is nil" do
      create(:absence, agent: agent, first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9), end_day: nil,
                       end_time: Tod::TimeOfDay.new(9, 40))
      expect(busy_times.first.ends_at).to eq(Time.zone.parse("20211027 9:40"))
    end

    it "returns BusyTime ends_at as absence end_day and end_time" do
      create(:absence, agent: agent, first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9),
                       end_day: Date.new(2021, 10, 28), end_time: Tod::TimeOfDay.new(12))
      expect(busy_times.first.ends_at).to eq(Time.zone.parse("20211028 12"))
    end

    context "absence is out of range" do
      let(:range) { Time.zone.parse("2021-10-26 9:00")..Time.zone.parse("2021-10-29 11:00") }

      it "doesn't return BusyTime" do
        create(:absence, agent: agent, first_day: Date.new(2021, 10, 29), start_time: Tod::TimeOfDay.new(14),
                         end_day: Date.new(2021, 10, 29), end_time: Tod::TimeOfDay.new(15))
        expect(busy_times).to be_empty
      end
    end
  end

  context "with an absence with recurrence" do
    it "returns starts_at first occurrence in range" do
      create(:absence, agent: agent, first_day: Date.new(2021, 10, 19), start_time: Tod::TimeOfDay.new(9),
                       recurrence: Montrose.every(:week, on: ["tuesday"], starts: Time.zone.parse("20211019 9:00"), until: nil, interval: 1))
      expect(busy_times.first.starts_at).to eq(Time.zone.parse("20211026 9:00"))
    end

    it "returns ends_at occurrence in range" do
      create(:absence, agent: agent, first_day: Date.new(2021, 10, 19), start_time: Tod::TimeOfDay.new(9),
                       end_time: Tod::TimeOfDay.new(9, 45), recurrence: Montrose.every(:week, on: ["tuesday"], starts: Time.zone.parse("20211019 9:00"), until: nil, interval: 1))
      expect(busy_times.first.ends_at).to eq(Time.zone.parse("20211026 9:45"))
    end

    it "returns a busy_time for each occurrence in range" do
      create(:absence,
             agent: agent,
             first_day: Date.new(2021, 10, 19),
             start_time: Tod::TimeOfDay.new(9),
             end_time: Tod::TimeOfDay.new(9, 45),
             recurrence: Montrose.every(:week, on: %w[tuesday friday], starts: Time.zone.parse("20211019 9:00"), until: nil, interval: 1))
      expect(busy_times.map(&:ends_at)).to eq([Time.zone.parse("20211026 9:45"), Time.zone.parse("20211029 9:45")])
    end

    context "if absence occurrence is out of range" do
      let(:range) { Time.zone.parse("2021-10-29 9:00")..Time.zone.parse("2021-10-29 11:00") }

      it "doesn't return BusyTime" do
        create(:absence, agent: agent, first_day: Date.new(2021, 10, 22),
                         start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(15),
                         recurrence: Montrose.every(:week, on: %w[tuesday friday], starts: Date.new(2021, 10, 22), until: nil, interval: 1))
        expect(busy_times).to be_empty
      end
    end
  end

  context "with an off_day in range" do
    context "with a range on a single day" do
      it "returns off_day from beginning of day to end of day" do
        christmas_morning = Time.zone.parse("2024-12-25 8:00")..Time.zone.parse("2024-12-25 12:00")
        busy_time = described_class.start_loading_busy_times_for(christmas_morning, agent, work_on_off_days: false).busy_times.first
        expect(busy_time.starts_at).to eq(Time.zone.parse("2024-12-25 0:00"))
        expect(busy_time.ends_at).to be_within(1.second).of(Time.zone.parse("2024-12-25 23:59:59"))
      end

      it "returns off_day that in given range only" do
        regular_monday_morning =  Time.zone.parse("2021-12-13 8:00")..Time.zone.parse("2021-12-13 12:00")
        expect(described_class.start_loading_busy_times_for(regular_monday_morning, agent, work_on_off_days: false).busy_times).to be_empty
      end
    end

    context "with a range spanning several days" do
      it "returns off_day from beginning of day to end of day" do
        christmas_week = Time.zone.parse("2024-12-20 8:00")..Time.zone.parse("2024-12-26 12:00")
        busy_time = described_class.start_loading_busy_times_for(christmas_week, agent, work_on_off_days: false).busy_times.first
        expect(busy_time.starts_at).to eq(Time.zone.parse("2024-12-25 0:00"))
        expect(busy_time.ends_at).to be_within(1.second).of(Time.zone.parse("2024-12-25 23:59:59"))
      end

      it "returns off_day that in given range only" do
        all_work_week = Time.zone.parse("2021-12-13 8:00")..Time.zone.parse("2021-12-19 12:00")
        expect(described_class.start_loading_busy_times_for(all_work_week, agent, work_on_off_days: false).busy_times).to be_empty
      end
    end
  end

  describe "request to fetch rdvs" do
    it "est optimisée pour utiliser l'index 'calculator_index'. Décommentez le test suivant si celui-ci échoue." do
      # Voir https://www.postgresql.org/docs/current/indexes-index-only-scans.html
      request = described_class.new(range, agent, work_on_off_days: false).send(:optimized_rdv_request)
      expect(request.select(:calculator_rdv_starts_at, :calculator_rdv_ends_at).to_sql.squish).to eq <<~SQL.squish
        SELECT "agents_rdvs"."calculator_rdv_starts_at",
               "agents_rdvs"."calculator_rdv_ends_at"
        FROM "agents_rdvs"
        WHERE "agents_rdvs"."agent_id" = #{agent.id}
          AND "agents_rdvs"."calculator_rdv_not_cancelled_and_in_the_future" = TRUE
          AND (tsrange(calculator_rdv_starts_at, calculator_rdv_ends_at, '[)') && tsrange('2021-10-26 06:00:00', '2021-10-29 10:00:00'))
      SQL
    end

    # Décommentez ces tests si vous changez la requête pour vérifier qu'elle reste rapide.
    # Ce test est trop long pour être ajouté à la CI pour chaque build (il faut créer beaucoup de données), mais il est utile si l'index ou la requête change
    # before do
    #   # Il faut créer un minimum de données pour que l'index soit utilisé (le query planner prend des décisions en fonction de la taille des tables et des indexes)
    #   100.times do |i|
    #     create(:rdv, starts_at: Time.zone.parse("20211027 9:00") + (i * 30.minutes), ends_at: Time.zone.parse("20211027 9:40") + (i * 30.minutes))
    #     create(:rdv, agents: [agent], starts_at: Time.zone.parse("20211027 9:00") + (i * 30.minutes), ends_at: Time.zone.parse("20211027 9:40") + (i * 30.minutes))
    #   end
    # end
    #
    # it "is optimized to use an index only scan" do
    #   # Voir https://www.postgresql.org/docs/current/indexes-index-only-scans.html
    #   request = described_class.new(range, agent).send(:optimized_rdv_request)
    #   expect(request.select(:calculator_rdv_starts_at, :calculator_rdv_ends_at).explain.inspect).to include "Index Only Scan using calculator_index"
    # end
  end
end
