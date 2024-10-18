RSpec.describe "PaperTrail::Version", versioning: true do
  describe "changes" do
    it "can read changes" do
      user = create(:user, first_name: "Frédérique")
      user.update(first_name: "Frédéric")
      expect(user.versions.last.changeset).to eq({ "first_name" => %w[Frédérique Frédéric] })
    end

    it "can read changes with Time" do
      now = Time.zone.parse("2022-04-21 12h30")
      travel_to(now - 1.day)
      user = create(:user)
      travel_to(now)
      user.update(confirmed_at: now)
      expect(user.versions.last.changeset).to eq({ "confirmed_at" => [
                                                   "2022-04-20T12:30:00.000+02:00",
                                                   "2022-04-21T12:30:00.000+02:00",
                                                 ] })
    end
  end
end
