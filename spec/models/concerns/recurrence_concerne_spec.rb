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
end
