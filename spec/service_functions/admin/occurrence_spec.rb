describe Admin::Occurrence, type: :service do
  describe "#extract_from" do
    it "return empty array when given elements is not an Array" do
      elements = "nothing"
      period = Date.new(2020, 3, 4)..Date.new(2020, 3, 11)
      expect(described_class.extract_from(elements, period)).to eq([])
    end

    it "return empty array when given elements does not respond to `occurrences_for`" do
      elements = [create(:absence), "bla"]
      period = Date.new(2020, 3, 4)..Date.new(2020, 3, 11)
      expect(described_class.extract_from(elements, period)).to eq([])
    end

    it "return occurrence object" do
      first_day = Date.new(2019, 8, 15)
      absence = create(:absence, first_day: first_day)
      period = Date.new(2019, 8, 12)..Date.new(2019, 8, 19)

      occurrences = described_class.extract_from([absence], period)
      expect(occurrences.map { |o| o.second.is_a?(Recurrence::Occurrence) }.uniq).to eq([true])
    end

    shared_examples "occurrences for" do |*elements|
      elements.each do |element|
        context element.to_s do
          it "return given #{element} as first entry of each entry" do
            first_day = Date.new(2019, 8, 15)
            object = create(element, first_day: first_day)
            second_object = create(element, first_day: first_day + 1)
            period = Date.new(2019, 8, 12)..Date.new(2019, 8, 19)

            first_entry_of_each_entries = described_class.extract_from(
              [object, second_object],
              period
            ).map(&:first)

            expect(first_entry_of_each_entries).to eq([object, second_object])
          end

          it " returns starts_at from given first_day " do
            starts_at = Time.zone.parse("2019-08-15 10h00:00")
            object = create(element, first_day: starts_at.to_date, start_time: starts_at.to_time)
            period = Date.new(2019, 8, 12)..Date.new(2019, 8, 19)

            occurrences = described_class.extract_from([object], period)
            expect(occurrences.first.second.starts_at).to eq(starts_at)
          end

          it "returns august 14th from 8h to 12h when recurrence interval for 2 weeks, and start on july 17th" do
            first_day = Date.new(2019, 7, 17)
            recurrence = Montrose.every(:week, interval: 2, starts: first_day)
            object = create(element, \
                            recurrence: recurrence, \
                            first_day: first_day, \
                            start_time: Time.zone.parse("8h00"), \
                            end_time: Time.zone.parse("12h00"))
            period = Date.new(2019, 8, 12)..Date.new(2019, 8, 19)

            expect_first_occurrence_to_match(described_class.extract_from([object], period), \
                                             starts_at: Time.zone.parse("2019-08-14 8h00"), \
                                             ends_at: Time.zone.parse("2019-08-14 12h00"))
          end

          it "returns july 31th without recurrence, only first day and time period" do
            first_day = Date.new(2019, 7, 31)
            object = create(element, \
                            recurrence: nil, \
                            first_day: first_day, \
                            start_time: Time.zone.parse("8h00"), \
                            end_time: Time.zone.parse("12h00"))
            period = Date.new(2019, 7, 29)..Date.new(2019, 8, 4)

            expect_first_occurrence_to_match(described_class.extract_from([object], period), \
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
end
