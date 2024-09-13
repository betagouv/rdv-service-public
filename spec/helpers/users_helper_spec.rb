RSpec.describe UsersHelper, type: :helper do
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

  describe "#default_service_selection_from" do
    context "user" do
      it "returns relative" do
        user = build(:user, :relative)
        expect(default_service_selection_from(user)).to eq(:relative)
      end

      it "returns responsible" do
        user = build(:user)
        expect(default_service_selection_from(user)).to eq(:responsible)
      end
    end

    context "service" do
      it "returns relative if pmi service" do
        service = build(:service, :pmi)
        expect(default_service_selection_from(service)).to eq(:relative)
      end

      it "returns responsible if other service" do
        service = build(:service, :social)
        expect(default_service_selection_from(service)).to eq(:responsible)
      end
    end
  end

  describe "full_name_and_birthdate" do
    before { travel_to Date.new(2021, 1, 1) }

    it "return only name when user without birthdate" do
      user = build(:user, birth_date: nil, first_name: "James", last_name: "BOND")
      expect(full_name_and_birthdate(user)).to eq("James BOND")
    end

    it "return name and birthdate when user with birthdate" do
      user = build(:user, birth_date: Date.new(1950, 12, 21), first_name: "James", last_name: "BOND")
      expect(full_name_and_birthdate(user)).to eq("James BOND - 21/12/1950 - 70 ans")
    end
  end

  describe "partially_hidden_reverse_full_name_and_notification_coordinates" do
    it "hides most of the personal data while allowing verification" do
      user = build(:user, birth_date: Date.new(1950, 12, 21), first_name: "Francis", last_name: "Factice", phone_number: "0611223344", notification_email: "francis@factice.com")
      expect(described_class.partially_hidden_reverse_full_name_and_notification_coordinates(user)).to eq("FACTICE Francis - 21/12/**** - 06******44 - f******s@factice.com")
    end

    it "doesn't fail for a user with missing info" do
      user = build(:user, birth_date: nil, first_name: "Francis", last_name: "Factice", phone_number: nil, notification_email: nil)
      expect(described_class.partially_hidden_reverse_full_name_and_notification_coordinates(user)).to eq("FACTICE Francis")

      user = build(:user, birth_date: nil, first_name: "Francis", last_name: "Factice", phone_number: "", notification_email: "")
      expect(described_class.partially_hidden_reverse_full_name_and_notification_coordinates(user)).to eq("FACTICE Francis")
    end
  end
end
