# frozen_string_literal: true

describe "PaperTrail::Version" do
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
      expect(user.versions.last.changeset).to eq({ "confirmed_at" => [now - 1.day, now] })
    end
  end
end
