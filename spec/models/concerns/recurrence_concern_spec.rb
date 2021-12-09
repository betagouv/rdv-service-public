# frozen_string_literal: true

describe RecurrenceConcern do
  describe "#all_occurrences_for" do
    shared_examples "occurrences for" do |*elements|
      elements.each do |element|
        element_class = element.to_s.classify.constantize

        context element.to_s do
          it "return given #{element} as first entry of each entry" do
            first_day = Date.new(2019, 8, 15)
            object = create(element, first_day: first_day)
            second_object = create(element, first_day: first_day + 1)
            period = Date.new(2019, 8, 12)..Date.new(2019, 8, 19)

            first_entry_of_each_entries = element_class.all_occurrences_for(period).map(&:first)

            expect(first_entry_of_each_entries).to eq([object, second_object])
          end

          it " returns starts_at from given first_day " do
            starts_at = Time.zone.parse("2019-08-15 10h00:00")
            create(element, first_day: starts_at.to_date, start_time: starts_at.to_time)
            period = Date.new(2019, 8, 12)..Date.new(2019, 8, 19)

            occurrences = element_class.all_occurrences_for(period)
            expect(occurrences.first.second.starts_at).to eq(starts_at)
          end

          it "returns august 14th from 8h to 12h when recurrence interval for 2 weeks, and start on july 17th" do
            first_day = Date.new(2019, 7, 17)
            recurrence = Montrose.every(:week, interval: 2, starts: first_day)
            create(element, \
                   recurrence: recurrence, \
                   first_day: first_day, \
                   start_time: Time.zone.parse("8h00"), \
                   end_time: Time.zone.parse("12h00"))
            period = Date.new(2019, 8, 12)..Date.new(2019, 8, 19)

            expect_first_occurrence_to_match(element_class.all_occurrences_for(period), \
                                             starts_at: Time.zone.parse("2019-08-14 8h00"), \
                                             ends_at: Time.zone.parse("2019-08-14 12h00"))
          end

          it "returns july 31th without recurrence, only first day and time period" do
            first_day = Date.new(2019, 7, 31)
            create(element, \
                   recurrence: nil, \
                   first_day: first_day, \
                   start_time: Time.zone.parse("8h00"), \
                   end_time: Time.zone.parse("12h00"))
            period = Date.new(2019, 7, 29)..Date.new(2019, 8, 4)

            expect_first_occurrence_to_match(element_class.all_occurrences_for(period), \
                                             starts_at: Time.zone.parse("2019-07-31 8h00"), \
                                             ends_at: Time.zone.parse("2019-07-31 12h00"))
          end
        end
      end
    end

    it_behaves_like "occurrences for", :absence, :plage_ouverture
  end

  def expect_first_occurrence_to_match(occurrences, expected_boundaries)
    first_occurrence = occurrences.first.second
    expect(first_occurrence.starts_at).to eq(expected_boundaries[:starts_at])
    expect(first_occurrence.ends_at).to eq(expected_boundaries[:ends_at])
  end

  describe "#in_range" do
    shared_examples "in range" do |*elements|
      elements.each do |element|
        element_class = element.to_s.classify.constantize

        context element.to_s do
          let(:monday) { Date.new(2021, 10, 4) }
          let(:range) { Date.new(2021, 10, 25)..Date.new(2021, 10, 29) }

          before do
            travel_to(monday)
          end

          context "without recurrence" do
            it "returns #{element} when first_day in range" do
              object = create(element, first_day: Date.new(2021, 10, 26), recurrence: nil)
              expect(element_class.in_range(range)).to eq([object])
            end

            it "dont returns #{element} when first_day after range" do
              create(element, first_day: Date.new(2021, 11, 26), recurrence: nil)
              expect(element_class.in_range(range)).to eq([])
            end

            it "dont returns #{element} when first_day before range" do
              create(element, first_day: Date.new(2021, 9, 26), recurrence: nil)
              expect(element_class.in_range(range)).to eq([])
            end
          end

          context "with recurrence" do
            it "returns #{element} when start in range" do
              first_day = Date.new(2021, 9, 26)
              object = create(element, first_day: first_day, recurrence: Montrose.every(:week, on: ["monday"], starts: first_day))
              expect(element_class.in_range(range)).to eq([object])
            end

            it "returns #{element} when ends in range" do
              first_day = range.begin - 1.month
              object = create(element, first_day: first_day, recurrence: Montrose.every(:week, on: ["monday"], starts: first_day, until: range.end - 2.days))
              expect(element_class.in_range(range)).to eq([object])
            end

            it "returns #{element} when start before range and end after range" do
              first_day = range.begin - 1.day
              object = create(element, first_day: first_day, recurrence: Montrose.every(:week, on: ["monday"], starts: first_day, until: range.end + 2.days))
              expect(element_class.in_range(range)).to eq([object])
            end

            it "returns #{element} when one occurrence start in range without until day" do
              range = Date.new(2021, 10, 25)..Date.new(2021, 10, 29)
              first_day = monday - 14.days
              object = create(element, first_day: first_day, recurrence: Montrose.every(:week, on: ["monday"], starts: first_day))
              expect(element_class.in_range(range)).to eq([object])
            end

            it "dont returns #{element} when end before range" do
              first_day = range.begin - 2.months
              create(element, first_day: first_day,
                              recurrence: Montrose.every(:week, on: ["monday"], starts: first_day, until: range.begin - 3.days))
              expect(element_class.in_range(range)).to eq([])
            end

            it "dont returns #{element} with recurrence start after range" do
              first_day = range.end + 4.days
              create(element, first_day: first_day,
                              recurrence: Montrose.every(:week, on: ["monday"], starts: first_day))
              expect(element_class.in_range(range)).to eq([])
            end
          end
        end
      end
    end
    it_behaves_like "in range", :absence, :plage_ouverture
  end

  describe "#recurrence_ends_after_first_day" do
    shared_examples "recurrence ends after first day" do |*elements|
      elements.each do |element|
        context element.to_s do
          it "valid #{element} when recurrence ends after first_day" do
            starts = Date.new(2021, 10, 27)
            recurring_object = build(element, first_day: starts, recurrence: Montrose.every(:week, on: ["wednesday"], starts: starts, until: starts + 1.week))
            expect(recurring_object).to be_valid
          end

          it "valid #{element} when recurrence ends is nil" do
            starts = Date.new(2021, 10, 27)
            recurring_object = build(element, first_day: starts, recurrence: Montrose.every(:week, on: ["wednesday"], starts: starts, until: nil))
            expect(recurring_object).to be_valid
          end

          it "invalid #{element} when recurrence ends at first_day" do
            starts = Date.new(2021, 10, 27)
            recurring_object = build(element, first_day: starts, recurrence: Montrose.every(:week, on: ["wednesday"], starts: starts, until: starts))
            expect(recurring_object).to be_invalid
          end

          it "invalid #{element} when recurrence ends before first_day" do
            starts = Date.new(2021, 10, 27)
            recurring_object = build(element, first_day: starts, recurrence: Montrose.every(:week, on: ["wednesday"], starts: starts, until: starts - 1.week))
            expect(recurring_object).to be_invalid
          end
        end
      end
    end

    it_behaves_like "recurrence ends after first day", :absence, :plage_ouverture
  end
end
