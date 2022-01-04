# frozen_string_literal: true

describe Expiration, type: :concern do
  shared_examples "#expired?" do
    def build(factory, params)
      # Absence has a :end_day attribute, but not PlageOuverture
      params.delete(:end_day) if described_class != Absence
      super(factory, **params)
    end

    it "is expired when end_day before today" do
      today = Time.zone.parse("20210323 13:45")
      travel_to(today)
      objet = build(factory, first_day: today - 5.days, end_day: today - 5.days)
      expect(objet.expired?).to be true
    end

    it "is not past when end_day after today" do
      today = Time.zone.parse("20210323 13:45")
      travel_to(today)
      objet = build(factory, first_day: today + 3.days, end_day: today + 3.days)
      expect(objet.expired?).to be false
    end

    it "is not past when end_day before today with a recurrence after today" do
      today = Time.zone.parse("20210323 13:45")
      travel_to(today)
      objet = build(factory, first_day: today - 1.day, end_day: today - 1.day, recurrence: Montrose.every(:week, until: today + 1.month, starts: today - 1.day))
      expect(objet.expired?).to be false
    end
  end

  [Absence, PlageOuverture].each do |klass|
    describe(klass) do
      let(:factory) { described_class.name.underscore }

      include_examples "#expired?"
    end
  end
end
