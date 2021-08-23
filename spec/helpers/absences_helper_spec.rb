# frozen_string_literal: true

describe AbsencesHelper do
  describe "#absence_tag" do
    it "return En cours when absence is today" do
      today = Time.zone.parse("2020-12-24 13:56")
      travel_to(today)
      absence = build(:absence, first_day: today.beginning_of_day, end_day: today.end_of_day)
      expect(absence_tag(absence)).to eq("<span class=\"badge badge-info\">En cours</span>")
    end

    it "return En cours when absence have an ocurrence today" do
      today = Time.zone.parse("2020-12-24 13:56")
      travel_to(today)
      absence = create(:absence,
                       first_day: today.beginning_of_day - 1.week,
                       end_day: today.end_of_day - 1.week,
                       recurrence: Montrose.every(:week, until: today + 1.month, starts: today.beginning_of_day - 1.week))

      expect(absence_tag(absence)).to eq("<span class=\"badge badge-info\">En cours</span>")
    end

    it "return nil when absence is for the future" do
      today = Time.zone.parse("2020-12-24 13:56")
      travel_to(today)
      absence = build(:absence,
                      first_day: today.beginning_of_day + 2.days,
                      end_day: today.end_of_day + 2.days)
      expect(absence_tag(absence)).to be_nil
    end

    it "return Passée when absence is expired" do
      today = Time.zone.parse("2020-12-24 13:56")
      travel_to(today)
      absence = build(:absence, first_day: today - 3.days, end_day: today - 3.days)
      expect(absence_tag(absence)).to eq("<span class=\"badge badge-light\">Passée</span>")
    end
  end
end
