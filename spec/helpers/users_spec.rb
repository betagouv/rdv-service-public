describe UsersHelper, type: :helper do
  describe "#age" do
    it "return 4 ans when born 4 years ago" do
      user = build(:user, birth_date: 4.years.ago)
      expect(age(user)).to eq("4 ans")
    end

    it "return 4 ans when born 5 years + 1 day ago" do
      user = build(:user, birth_date: 5.years.ago + 1.day)
      expect(age(user)).to eq("4 ans")
    end

    it "return 35 mois when born 35 months ago" do
      user = build(:user, birth_date: 35.months.ago)
      expect(age(user)).to eq("35 mois")
    end

    it "return 3 ans whern born 36 months ago" do
      user = build(:user, birth_date: 36.months.ago)
      expect(age(user)).to eq("3 ans")
    end

    it "born 20 days ago" do
      user = build(:user, birth_date: 20.days.ago)
      expect(age(user)).to eq("20 jours")
    end
  end
end
