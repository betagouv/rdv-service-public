describe DisplayableUserPresenter, type: :presenter do
  describe "#birth_date" do
    it "return something" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], birth_date: Date.new(1976, 10, 23))
      displayable_user = DisplayableUserPresenter.new(user, organisation)
      expect(displayable_user.birth_date).to eq("23/10/1976 - 44 ans")
    end
  end

  describe "#user" do
    it "return given user" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation])
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.user).to eq(user)
    end
  end

  describe "delegation user's attributes" do
    [:first_name, :last_name, :birth_name, :address, :affiliation_number, :number_of_children].each do |attribute|
      it "delegate #{attribute} to user" do
        organisation = build(:organisation)
        user = build(:user, organisations: [organisation])
        displayable_user = described_class.new(user, organisation)
        expect(displayable_user.send(attribute)).to eq(user.send(attribute))
      end
    end
  end

  describe "#caisse_affiliation" do
    it "return user enum value for caisse d'affiliation" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], caisse_affiliation: 1)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.caisse_affiliation).to eq("CAF")
    end
  end

  describe "#family_situation" do
    it "return user's family_situation" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], family_situation: 1)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.family_situation).to eq("En couple")
    end
  end

  describe "#phone_number" do
    it "return user's phone_number" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], phone_number: "01 23 45 67 89")
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.phone_number).to eq("01 23 45 67 89")
    end

    it "return user's responsible phone_number" do
      organisation = build(:organisation)
      responsible = build(:user, organisations: [organisation], phone_number: "98 78 45 56 32")
      user = build(:user, organisations: [organisation], phone_number: nil, responsible: responsible)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.phone_number).to eq("98 78 45 56 32")
    end
  end

  describe "#email" do
    it "return user's email" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], email: "truc@bla.com")
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.email).to eq("truc@bla.com")
    end

    it "return user's responsible email" do
      organisation = build(:organisation)
      responsible = build(:user, organisations: [organisation], email: "bla@truc.net")
      user = build(:user, organisations: [organisation], email: nil, responsible: responsible)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.email).to eq("bla@truc.net")
    end
  end

  describe "#logement" do
    it "return user's logement from profile" do
      organisation = create(:organisation)
      user_profile = create(:user_profile, organisation: organisation, logement: 1)
      user = create(:user, organisations: [organisation], user_profiles: [user_profile])
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.logement).to eq("Hébergé")
    end
  end

  describe "#notes" do
    it "return user's profile notes" do
      organisation = create(:organisation)
      user_profile = create(:user_profile, organisation: organisation, notes: "Quelques notes")
      user = create(:user, organisations: [organisation], user_profiles: [user_profile])
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.notes).to eq("<p>Quelques notes</p>")
    end
  end

  describe "#notify_by_sms" do
    it "returns no phone number when user dont have phone number" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], phone_number: nil)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.notify_by_sms).to eq("pas de numéro de téléphone renseigné")
    end

    it "return activated when user allow sms notifications" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], phone_number: "01 02 03 04 05", notify_by_sms: true)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.notify_by_sms).to eq("🟢 Activées")
    end

    it "return desactivated when user disallow sms notifications" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], phone_number: "01 02 03 04 05", notify_by_sms: false)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.notify_by_sms).to eq("🔴 Désactivées")
    end
  end

  describe "#notify_by_email" do
    it "return no email when user responsible don't have email" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], email: nil)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.notify_by_email).to eq("pas d'email renseigné")
    end

    it "return activées when user allow notification_by_email" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], email: "truc@bla.net", notify_by_email: true)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.notify_by_email).to eq("🟢 Activées")
    end

    it "return desactivées when user disallow notification by email" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], email: "truc@bla.net", notify_by_email: false)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.notify_by_email).to eq("🔴 Désactivées")
    end
  end

  describe "#email_and_notification" do
    it "returns N/A when no email in user" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], email: nil)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.email_and_notification).to eq("N/A")
    end

    it "returns email and activate notification with a user's email and notification activated" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], email: "bob@eponge.net", notify_by_email: true)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.email_and_notification).to eq("<a href=\"mailto:bob@eponge.net\">bob@eponge.net</a> - Notifications par email 🟢 Activées")
    end

    it "returns email and activate notification with a user's email and notification desactivated" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], email: "bob@eponge.net", notify_by_email: false)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.email_and_notification).to eq("<a href=\"mailto:bob@eponge.net\">bob@eponge.net</a> - Notifications par email 🔴 Désactivées")
    end
  end

  describe "#phone_number_and_notification" do
    it "returns N/A when no phone in user" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], phone_number: nil)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.phone_number_and_notification).to eq("N/A")
    end

    it "returns phone_number and activate notification with a user's email and notification activated" do
      organisation = build(:organisation)
      user = create(:user, organisations: [organisation], phone_number: "01 02 03 04 05", notify_by_sms: true)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.phone_number_and_notification).to eq("<a href=\"tel:+33102030405\">01 02 03 04 05</a> - Notifications par SMS 🟢 Activées")
    end

    it "returns phone_number and activate notification with a user's email and notification desactivated" do
      organisation = build(:organisation)
      user = create(:user, organisations: [organisation], phone_number: "01 02 03 04 05", notify_by_sms: false)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.phone_number_and_notification).to eq("<a href=\"tel:+33102030405\">01 02 03 04 05</a> - Notifications par SMS 🔴 Désactivées")
    end
  end

  describe "#clickable_email" do
    it "returns N/A when no email in user" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], email: nil)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.clickable_email).to eq("N/A")
    end

    it "returns clickable email with a user's email" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], email: "bob@eponge.net", notify_by_email: true)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.clickable_email).to eq("<a href=\"mailto:bob@eponge.net\">bob@eponge.net</a>")
    end
  end

  describe "#clickable_phone_number" do
    it "returns N/A when no phone in user" do
      organisation = build(:organisation)
      user = build(:user, organisations: [organisation], phone_number: nil)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.clickable_phone_number).to eq("N/A")
    end

    it "returns clickable phone_number with a user's phone_number" do
      organisation = build(:organisation)
      user = create(:user, organisations: [organisation], phone_number: "01 02 03 04 05", notify_by_sms: true)
      displayable_user = described_class.new(user, organisation)
      expect(displayable_user.clickable_phone_number).to eq("<a href=\"tel:+33102030405\">01 02 03 04 05</a>")
    end
  end
end
