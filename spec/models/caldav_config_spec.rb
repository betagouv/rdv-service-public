RSpec.describe CaldavConfig do
  it "is valid without a caldav_calendar_color" do
    expect(build(:caldav_config, caldav_calendar_color: nil)).to be_valid
  end

  it "invalid without #RRGGBB format's caldav_calendar_color" do
    expect(build(:caldav_config, caldav_calendar_color: "bleu")).to be_invalid
    expect(build(:caldav_config, caldav_calendar_color: "003399")).to be_invalid
    expect(build(:caldav_config, caldav_calendar_color: "#003399")).to be_valid
  end
end
