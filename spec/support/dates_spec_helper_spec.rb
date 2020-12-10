describe DatesSpecHelper, type: :helper do
  describe "#get_next_week_working_weekday" do
    context "next weekday is not a holiday" do
      before { travel_to(Date.new(2020, 12, 15)) }
      subject { get_next_week_working_weekday(:monday) }
      it { should eq(Date.new(2020, 12, 21)) }
    end

    context "next weekday is a holiday" do
      before { travel_to(Date.new(2020, 12, 19)) }
      subject { get_next_week_working_weekday(:friday) } # next fridays are christmas then nye
      it { should eq(Date.new(2021, 1, 8)) } # thus it skips 2 fridays
    end

    context "next weekday's day after is a holiday, with default 1 day inclusion" do
      before { travel_to(Date.new(2020, 12, 19)) }
      subject { get_next_week_working_weekday(:thursday) } # next friday is christmas
      it { should eq(Date.new(2020, 12, 24)) }
    end

    context "next weekday's day after is a holiday, with 2 days inclusion" do
      before { travel_to(Date.new(2020, 12, 19)) }
      subject { get_next_week_working_weekday(:thursday, consecutive_working_days: 2) } # next fridays are christmas then nye
      it { should eq(Date.new(2021, 1, 7)) } # thus it skips 2 thursdays
    end
  end
end
