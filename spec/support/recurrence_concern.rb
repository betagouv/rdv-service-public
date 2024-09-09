RSpec.shared_examples_for "recurrence" do
  let(:model) { described_class }
  let(:model_symbol) { model.to_s.underscore.to_sym }

  describe "#starts_at" do
    subject { model_instance.starts_at }

    context "exceptionnelle" do
      let(:model_instance) { create(model_symbol, first_day: Date.new(2019, 7, 22), start_time: Tod::TimeOfDay.new(9)) }

      it { is_expected.to eq(Time.zone.local(2019, 7, 22, 9)) }
    end
  end

  describe "#ends_at" do
    subject { model_instance.ends_at }

    context "exceptionnelle" do
      let(:model_instance) { create(model_symbol, first_day: Date.new(2019, 7, 22), end_time: Tod::TimeOfDay.new(12)) }

      it { is_expected.to eq(Time.zone.local(2019, 7, 22, 12)) }
    end

    context "recurring without end date" do
      let(:first_day) { Date.new(2019, 7, 22).in_time_zone }
      let(:model_instance) { create(model_symbol, first_day: first_day, end_time: Tod::TimeOfDay.new(12), recurrence: Montrose.every(:week, on: [:tuesday], starts: first_day)) }

      it { is_expected.to be_nil }
    end

    context "recurring with end date" do
      let(:first_day) { Date.new(2019, 11, 17).in_time_zone }
      let(:model_instance) do
        create(model_symbol, first_day: first_day, end_time: Tod::TimeOfDay.new(12), recurrence: Montrose.every(:week, on: [:tuesday], starts: first_day, until: Date.new(2020, 11, 25).in_time_zone))
      end

      it { is_expected.to eq(Time.zone.local(2020, 11, 25, 12)) }
    end
  end

  describe "#occurrences_for" do
    subject { model_instance.occurrences_for(date_range) }

    let(:date_range) { Date.new(2019, 7, 22)..Date.new(2019, 7, 28) }

    context "when there is no recurrence" do
      let(:model_instance) { build(model_symbol, :no_recurrence, first_day: Date.new(2019, 7, 22)) }

      it do
        expect(subject.size).to eq 1
        expect(subject.first.starts_at).to eq model_instance.starts_at
        expect(subject.first.ends_at).to eq model_instance.first_occurrence_ends_at
      end

      context "and the first_day is the last of the range" do
        let(:model_instance) { build(model_symbol, :no_recurrence, first_day: date_range.end) }

        it do
          expect(subject.size).to eq 1
          expect(subject.first.starts_at).to eq model_instance.starts_at
          expect(subject.first.ends_at).to eq model_instance.first_occurrence_ends_at
        end
      end
    end

    context "when there is a daily recurrence" do
      let(:model_instance) { build(model_symbol, :daily, first_day: Date.new(2019, 7, 22)) }
      let(:date_range) { Date.new(2019, 7, 22)..Date.new(2019, 7, 28) }

      it do
        expect(subject.size).to eq 7
        expect(subject[0].starts_at).to eq(model_instance.starts_at)
        expect(subject[0].ends_at).to eq(model_instance.first_occurrence_ends_at)
        expect(subject[1].starts_at).to eq(model_instance.starts_at + 1.day)
        expect(subject[1].ends_at).to eq(model_instance.first_occurrence_ends_at + 1.day)
        expect(subject[2].starts_at).to eq(model_instance.starts_at + 2.days)
        expect(subject[2].ends_at).to eq(model_instance.first_occurrence_ends_at + 2.days)
        expect(subject[3].starts_at).to eq(model_instance.starts_at + 3.days)
        expect(subject[3].ends_at).to eq(model_instance.first_occurrence_ends_at + 3.days)
        expect(subject[4].starts_at).to eq(model_instance.starts_at + 4.days)
        expect(subject[4].ends_at).to eq(model_instance.first_occurrence_ends_at + 4.days)
        expect(subject[5].starts_at).to eq(model_instance.starts_at + 5.days)
        expect(subject[5].ends_at).to eq(model_instance.first_occurrence_ends_at + 5.days)
        expect(subject[6].starts_at).to eq(model_instance.starts_at + 6.days)
        expect(subject[6].ends_at).to eq(model_instance.first_occurrence_ends_at + 6.days)
      end
    end

    context "when there is a weekly recurrence" do
      let(:model_instance) { build(model_symbol, :weekly, first_day: Date.new(2019, 7, 22)) }
      let(:date_range) { Date.new(2019, 7, 22)..Date.new(2019, 8, 7) }

      it do
        expect(subject.size).to eq 3
        expect(subject[0].starts_at).to eq(model_instance.starts_at)
        expect(subject[0].ends_at).to eq(model_instance.first_occurrence_ends_at)
        expect(subject[1].starts_at).to eq(model_instance.starts_at + 1.week)
        expect(subject[1].ends_at).to eq(model_instance.first_occurrence_ends_at + 1.week)
        expect(subject[2].starts_at).to eq(model_instance.starts_at + 2.weeks)
        expect(subject[2].ends_at).to eq(model_instance.first_occurrence_ends_at + 2.weeks)
      end
    end

    context "when there is a weekly recurrence with an interval of 2" do
      let(:model_instance) { build(model_symbol, :every_two_weeks, first_day: Date.new(2019, 7, 22)) }
      let(:date_range) { Date.new(2019, 7, 22)..Date.new(2019, 8, 7) }

      it do
        expect(subject.size).to eq 2
        expect(subject[0].starts_at).to eq(model_instance.starts_at)
        expect(subject[0].ends_at).to eq(model_instance.first_occurrence_ends_at)
        expect(subject[1].starts_at).to eq(model_instance.starts_at + 2.weeks)
        expect(subject[1].ends_at).to eq(model_instance.first_occurrence_ends_at + 2.weeks)
      end
    end

    context "when there is a daily recurrence and until is set" do
      let(:first_day) { Date.new(2019, 7, 22) }
      let(:model_instance) do
        build(model_symbol, first_day: first_day,
                            start_time: Tod::TimeOfDay.new(8),
                            end_time: Tod::TimeOfDay.new(12),
                            recurrence: Montrose.every(:day, starts: first_day, until: Date.new(2019, 8, 5)).to_json,
                            recurrence_ends_at: Date.new(2019, 8, 5))
      end
      let(:date_range) { Date.new(2019, 8, 5)..Date.new(2019, 8, 11) }

      it do
        expect(subject.size).to eq 1
        expect(subject[0].starts_at).to eq(Time.zone.local(2019, 8, 5, 8))
        expect(subject[0].ends_at).to eq(Time.zone.local(2019, 8, 5, 12))
      end
    end

    describe "the future_only parameter" do
      # In june of 2022, wednesdays land on 1, 8, 15, 22 and 29.
      # Let's create a recurrent event that repeats on wednesdays beginning june 1st.
      # Let's say we wish to search on the whole month (date range is june 1st to 30th).
      # Let's say today is monday 13th of june.
      # Using `future_only: false` should return all wednesdays (1, 8, 15, 22 and 29).
      # Using `future_only: true` should return future wednesdays (15, 22 and 29).

      before { travel_to(Time.zone.local(2022, 6, 13)) }

      let(:first_day) { Date.new(2022, 6, 1) }
      let(:model_instance) do
        build(model_symbol,
              first_day: first_day,
              start_time: Tod::TimeOfDay.new(8),
              end_time: Tod::TimeOfDay.new(12),
              recurrence: Montrose.every(
                :week,
                on: [:wednesday],
                interval: 1,
                starts: first_day
              ).to_json)
      end
      let(:date_range) { Date.new(2022, 6, 1)..Date.new(2022, 6, 30) }

      context "when using the future_only: false switch" do
        subject { model_instance.occurrences_for(date_range, only_future: false) }

        it "returns all wednesdays of june" do
          all_wednesdays_of_june = [
            Time.zone.parse("2022-06-01 08:00:00"),
            Time.zone.parse("2022-06-08 08:00:00"),
            Time.zone.parse("2022-06-15 08:00:00"),
            Time.zone.parse("2022-06-22 08:00:00"),
            Time.zone.parse("2022-06-29 08:00:00"),
          ]
          expect(subject.map(&:starts_at)).to eq(all_wednesdays_of_june)
        end
      end
    end
  end
end
