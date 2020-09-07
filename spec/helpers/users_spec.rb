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

  describe "#users_to_sentence" do
    it "return nothing without current agent and no agents for rdv" do
      current_agent = nil
      current_user = build(:user)
      user = build(:user, first_name: "Jade", last_name: "MAILLARD")
      users = [user]
      expect(users_to_sentence(users, current_agent, current_user)).to eq("")
    end

    it "Return user full name with a current agent" do
      current_agent = build(:agent)
      current_user = nil
      user = build(:user, first_name: "Jade", last_name: "MAILLARD")
      users = [user]
      expect(users_to_sentence(users, current_agent, current_user)).to eq("Jade MAILLARD")
    end

    it "Return user full name with a current user as rdv's user " do
      current_agent = nil
      current_user = build(:user, first_name: "Jade", last_name: "MAILLARD")
      users = [current_user]
      expect(users_to_sentence(users, current_agent, current_user)).to eq("Jade MAILLARD")
    end

    it "Return user full name only for current_user as rdv's user (exclude other not relative users) " do
      current_agent = nil
      current_user = build(:user, first_name: "Jade", last_name: "MAILLARD")
      other_user = build(:user, first_name: "André", last_name: "CITRON")
      users = [current_user, other_user]
      expect(users_to_sentence(users, current_agent, current_user)).to eq("Jade MAILLARD")
    end

    it "Return current user and relatives full name" do
      current_agent = nil
      relative_user = build(:user, first_name: "André", last_name: "CITRON")
      current_user = build(:user, first_name: "Jade", last_name: "MAILLARD", relatives: [relative_user])
      users = [current_user, relative_user]
      expect(users_to_sentence(users, current_agent, current_user)).to eq("André CITRON et Jade MAILLARD")
    end
  end
end
