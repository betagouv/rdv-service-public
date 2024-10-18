RSpec.describe RecurrenceConcern do
  shared_examples "#set_recurrence_ends_at" do
    it "set to ends of day of last occurrence" do
      first_day = Date.new(2019, 8, 15)
      recurrence = Montrose.every(:week, interval: 2, starts: first_day, until: first_day + 7.days)
      object = build(factory, first_day: first_day, recurrence: recurrence)
      object.save!
      expect(object.reload.recurrence_ends_at).to be_within(1.second).of(Time.zone.parse("20190822 23:59:59"))
    end
  end

  shared_examples "#all_occurrences_for" do
    def expect_first_occurrence_to_match(occurrences, expected_boundaries)
      first_occurrence = occurrences.first.second
      expect(first_occurrence.starts_at).to eq(expected_boundaries[:starts_at])
      expect(first_occurrence.ends_at).to eq(expected_boundaries[:ends_at])
    end

    it "return given element as first entry of each entry" do
      first_day = Date.new(2019, 8, 15)
      object = create(factory, first_day: first_day)
      second_object = create(factory, first_day: first_day + 1)
      period = Date.new(2019, 8, 12)..Date.new(2019, 8, 19)

      first_entry_of_each_entries = described_class.all_occurrences_for(period).map(&:first)

      expect(first_entry_of_each_entries).to eq([object, second_object])
    end

    it "returns starts_at from given first_day" do
      starts_at = Time.zone.parse("2019-08-15 10h00:00")
      create(factory, first_day: starts_at.to_date, start_time: starts_at)
      period = Date.new(2019, 8, 12)..Date.new(2019, 8, 19)

      occurrences = described_class.all_occurrences_for(period)
      expect(occurrences.first.second.starts_at).to eq(starts_at)
    end

    it "returns august 14th from 8h to 12h when recurrence interval for 2 weeks, and start on july 17th" do
      first_day = Date.new(2019, 7, 17)
      recurrence = Montrose.every(:week, interval: 2, starts: first_day)
      create(factory,
             recurrence: recurrence,
             first_day: first_day, \
             start_time: Time.zone.parse("8h00"), \
             end_time: Time.zone.parse("12h00"))
      period = Date.new(2019, 8, 12)..Date.new(2019, 8, 19)

      expect_first_occurrence_to_match(described_class.all_occurrences_for(period),
                                       starts_at: Time.zone.parse("2019-08-14 8h00"),
                                       ends_at: Time.zone.parse("2019-08-14 12h00"))
    end

    it "returns july 31th without recurrence, only first day and time period" do
      first_day = Date.new(2019, 7, 31)
      create(factory,
             recurrence: nil,
             first_day: first_day, \
             start_time: Time.zone.parse("8h00"), \
             end_time: Time.zone.parse("12h00"))
      period = Date.new(2019, 7, 29)..Date.new(2019, 8, 4)

      expect_first_occurrence_to_match(described_class.all_occurrences_for(period),
                                       starts_at: Time.zone.parse("2019-07-31 8h00"),
                                       ends_at: Time.zone.parse("2019-07-31 12h00"))
    end

    it "doesn't return occurrences for an object with a finished recurrence" do
      create(factory, recurrence: Montrose.every(:week, on: [:monday], starts: Date.new(2019, 7, 1), until: Date.new(2019, 7, 22), interval: 1),
                      first_day: Date.new(2019, 7, 1), start_time: Time.zone.parse("8h00"),
                      end_time: Time.zone.parse("12h00"))

      # On vérifie que le filtre est fait au niveau sql plutôt qu'en instanciant des objets
      expect_any_instance_of(described_class).not_to receive(:occurrences_for) # rubocop:disable RSpec/AnyInstance

      expect(described_class.all_occurrences_for(Date.new(2019, 7, 23)..Date.new(2019, 8, 15))).to be_empty
    end

    it "returns the last occurrence when it's the first day of the date range" do
      object = create(factory, recurrence: Montrose.every(:week, on: [:monday], starts: Date.new(2019, 7, 1), until: Date.new(2019, 7, 22), interval: 1),
                               first_day: Date.new(2019, 7, 1), start_time: Time.zone.parse("8h00"),
                               end_time: Time.zone.parse("12h00"))

      expect(described_class.all_occurrences_for(Date.new(2019, 7, 22)..Date.new(2019, 7, 23))).to contain_exactly(
        [object, Recurrence::Occurrence.new(starts_at: Time.zone.parse("2019-7-22, 8h00"), ends_at: Time.zone.parse("2019-7-22, 12h00"))]
      )
    end
  end

  shared_examples "#in_range" do
    let(:monday) { Date.new(2021, 10, 4) }
    let(:range) { Date.new(2021, 10, 25)..Date.new(2021, 10, 29) }

    before do
      travel_to(monday)
    end

    context "without recurrence" do
      it "returns element when first_day in range" do
        object = create(factory, first_day: Date.new(2021, 10, 26), recurrence: nil)
        expect(described_class.in_range(range)).to eq([object])
      end

      it "doesnt return element when first_day after range" do
        create(factory, first_day: Date.new(2021, 11, 26), recurrence: nil)
        expect(described_class.in_range(range)).to eq([])
      end

      it "doesnt return element when first_day before range" do
        create(factory, first_day: Date.new(2021, 9, 26), recurrence: nil)
        expect(described_class.in_range(range)).to eq([])
      end

      if described_class == Absence
        it "returns element when last_day in range" do
          object = create(factory, first_day: Date.new(2021, 9, 26), end_day: Date.new(2021, 10, 27), recurrence: nil)
          expect(described_class.in_range(range)).to eq([object])
        end

        it "returns element when start_day before range and last_day after range" do
          object = create(factory, first_day: Date.new(2021, 9, 26), end_day: Date.new(2021, 10, 30), recurrence: nil)
          expect(described_class.in_range(range)).to eq([object])
        end
      end
    end

    context "with recurrence" do
      it "returns element when start in range" do
        first_day = Date.new(2021, 9, 26)
        object = create(factory, first_day: first_day, recurrence: Montrose.every(:week, on: ["monday"], starts: first_day, interval: 1))
        expect(described_class.in_range(range)).to eq([object])
      end

      it "returns element when ends in range" do
        first_day = range.begin - 1.month
        object = create(factory, first_day: first_day, recurrence: Montrose.every(:week, on: ["monday"], starts: first_day, until: range.end - 2.days, interval: 1))
        expect(described_class.in_range(range)).to eq([object])
      end

      it "returns element when start before range and end after range" do
        first_day = range.begin - 1.day
        object = create(factory, first_day: first_day, recurrence: Montrose.every(:week, on: ["monday"], starts: first_day, until: range.end + 2.days, interval: 1))
        expect(described_class.in_range(range)).to eq([object])
      end

      it "returns element when one occurrence start in range without until day" do
        range = Date.new(2021, 10, 25)..Date.new(2021, 10, 29)
        first_day = monday - 14.days
        object = create(factory, first_day: first_day, recurrence: Montrose.every(:week, on: ["monday"], starts: first_day, interval: 1))
        expect(described_class.in_range(range)).to eq([object])
      end

      it "doesnt return element when end before range" do
        first_day = range.begin - 2.months
        create(factory, first_day: first_day,
                        recurrence: Montrose.every(:week, on: ["monday"], starts: first_day, until: range.begin - 3.days, interval: 1))
        expect(described_class.in_range(range)).to eq([])
      end

      it "returns element when first day of range at the until day" do
        range = Time.zone.parse("2021-10-25 0:00")..Time.zone.parse("2021-10-29 23:59:59.99")
        first_day = monday - 14.days
        object = create(factory, first_day: first_day, recurrence: Montrose.every(:week, on: ["monday"], starts: first_day, until: range.begin.to_date, interval: 1))
        expect(described_class.in_range(range)).to eq([object])
      end

      it "doesnt return element with recurrence start after range" do
        first_day = range.end + 4.days
        create(factory, first_day: first_day,
                        recurrence: Montrose.every(:week, on: ["monday"], starts: first_day, interval: 1))
        expect(described_class.in_range(range)).to eq([])
      end
    end
  end

  shared_examples "#recurrence_ends_after_first_day" do
    it "valid element when recurrence ends after first_day" do
      starts = Date.new(2021, 10, 27)
      recurring_object = build(factory, first_day: starts, recurrence: Montrose.every(:week, on: ["wednesday"], starts: starts, until: starts + 1.week, interval: 1))
      expect(recurring_object).to be_valid
    end

    it "valid element when recurrence ends is nil" do
      starts = Date.new(2021, 10, 27)
      recurring_object = build(factory, first_day: starts, recurrence: Montrose.every(:week, on: ["wednesday"], starts: starts, until: nil, interval: 1))
      expect(recurring_object).to be_valid
    end

    it "invalid element when recurrence ends at first_day" do
      starts = Date.new(2021, 10, 27)
      recurring_object = build(factory, first_day: starts, recurrence: Montrose.every(:week, on: ["wednesday"], starts: starts, until: starts, interval: 1))
      expect(recurring_object).to be_invalid
    end

    it "invalid element when recurrence ends before first_day" do
      starts = Date.new(2021, 10, 27)
      recurring_object = build(factory, first_day: starts, recurrence: Montrose.every(:week, on: ["wednesday"], starts: starts, until: starts - 1.week, interval: 1))
      expect(recurring_object).to be_invalid
    end
  end

  [Absence, PlageOuverture].each do |klass|
    describe(klass) do
      let(:factory) { described_class.name.underscore }

      include_examples "#all_occurrences_for"
      include_examples "#in_range"
      include_examples "#recurrence_ends_after_first_day"
      include_examples "#set_recurrence_ends_at"
    end
  end
end
