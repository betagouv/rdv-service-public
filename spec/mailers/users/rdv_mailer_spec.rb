RSpec.describe Users::RdvMailer, type: :mailer do
  describe "#rdv_created" do
    let(:rdv) { create(:rdv) }
    let(:user) { rdv.users.first }
    let(:mail) { described_class.rdv_created(rdv, user) }

    it "renders the headers" do
      expect(mail.to).to eq([user.email])
    end

    it "renders the subject" do
      expect(mail.subject).to eq("RDV confirmé le #{I18n.l(rdv.starts_at, format: :human)}")
    end

    it "renders the body" do
      expect(mail.html_part.body.encoded).to match("Votre RDV du #{I18n.l(rdv.starts_at, format: :human)} a été confirmé")
    end

    it "contains the ics" do
      expect(mail.body.encoded).to match("UID:#{rdv.uuid}")
      expect(mail.body.encoded).to match("STATUS:CANCELLED") if rdv.cancelled?
    end
  end

  describe "#rdv_cancelled_by_user" do
    it "send mail to user" do
      rdv = create(:rdv)
      user = rdv.users.first
      mail = described_class.rdv_cancelled_by_user(rdv, user)

      expect(mail.to).to eq([user.email])
    end

    it "subject contains date of cancelled rdv" do
      organisation = build(:organisation, name: "Orga du coin")
      user = build(:user)
      rdv = build(:rdv, starts_at: Time.zone.parse("2020-06-15 12:30"), organisation: organisation, users: [user])
      mail = described_class.rdv_cancelled_by_user(rdv, user)

      expect(mail.subject).to eq("RDV annulé le lundi 15 juin 2020 à 12h30 avec Orga du coin")
    end

    it "body contains cancelled confirmation with dateTime" do
      organisation = build(:organisation, name: "Orga du coin")
      user = build(:user)
      rdv = build(:rdv, starts_at: Time.zone.parse("2020-06-15 12:30"), organisation: organisation, users: [user])
      mail = described_class.rdv_cancelled_by_user(rdv, user)

      expect(mail.body).to match("lundi 15 juin 2020 à 12h30")
    end

    it "body contains cancelled confirmation with motif's service name" do
      organisation = build(:organisation, name: "Orga du coin")
      user = build(:user)
      rdv = build(:rdv, starts_at: Time.zone.parse("2020-06-15 12:30"), organisation: organisation, users: [user])
      mail = described_class.rdv_cancelled_by_user(rdv, user)

      expect(mail.body).to match(rdv.motif.service_name)
    end

    it "body contains link to book a new RDV" do
      organisation = build(:organisation, name: "Orga du coin")
      user = build(:user)
      rdv = build(:rdv, starts_at: Time.zone.parse("2020-06-15 12:30"), organisation: organisation, users: [user])
      mail = described_class.rdv_cancelled_by_user(rdv, user)

      expected_url = lieux_url(search: { \
                                 departement: rdv.organisation.departement_number, \
                                 motif_name_with_location_type: rdv.motif.name_with_location_type, \
                                 service: rdv.motif.service.id, \
                                 where: rdv.address \
                               })

      expect(mail.body).to have_link("Reprendre RDV", href: expected_url)
    end
  end

  describe "#rdv_cancelled_by_agent" do
    it "send mail to user" do
      rdv = create(:rdv)
      user = rdv.users.first
      mail = described_class.rdv_cancelled_by_agent(rdv, user)

      expect(mail.to).to eq([user.email])
    end

    it "subject contains date of cancelled rdv" do
      organisation = build(:organisation, name: "Orga du coin")
      user = build(:user)
      rdv = build(:rdv, starts_at: Time.zone.parse("2020-06-15 12:30"), organisation: organisation, users: [user])
      mail = described_class.rdv_cancelled_by_user(rdv, user)

      expect(mail.subject).to eq("RDV annulé le lundi 15 juin 2020 à 12h30 avec Orga du coin")
    end

    it "body contains cancelled confirmation with dateTime" do
      organisation = build(:organisation, name: "Orga du coin")
      user = build(:user)
      rdv = build(:rdv, starts_at: Time.zone.parse("2020-06-15 12:30"), organisation: organisation, users: [user])
      mail = described_class.rdv_cancelled_by_agent(rdv, user)

      expect(mail.body).to match("lundi 15 juin 2020 à 12h30")
    end

    it "body contains cancelled confirmation with motif's service name" do
      organisation = build(:organisation, name: "Orga du coin")
      user = build(:user)
      rdv = build(:rdv, starts_at: Time.zone.parse("2020-06-15 12:30"), organisation: organisation, users: [user])
      mail = described_class.rdv_cancelled_by_agent(rdv, user)

      expect(mail.body).to match(rdv.motif.service_name)
    end
  end

  it "send mail to user" do
    rdv = create(:rdv)
    user = rdv.users.first
    mail = described_class.rdv_upcoming_reminder(rdv, user)
    expect(mail.to).to eq([user.email])
    expect(mail.body).to include("Nous vous rappellons que vous avez un RDV prévu")
  end
end
