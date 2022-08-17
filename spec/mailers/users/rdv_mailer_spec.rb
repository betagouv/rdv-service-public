# frozen_string_literal: true

RSpec.describe Users::RdvMailer, type: :mailer do
  describe "#rdv_created" do
    let(:rdv) { create(:rdv) }
    let(:user) { rdv.users.first }
    let(:token) { "12345" }
    let(:mail) { described_class.with(rdv: rdv, user: user, token: token).rdv_created }

    it "renders the headers" do
      expect(mail.to).to eq([user.email])
      expect(mail.reply_to).to eq(["rdv+#{rdv.uuid}@reply.rdv-solidarites.fr"])
    end

    it "renders the subject" do
      expect(mail.subject).to eq("RDV confirmé le #{I18n.l(rdv.starts_at, format: :human)}")
    end

    it "renders the body" do
      expect(mail.html_part.body.encoded).to match("Votre RDV du #{I18n.l(rdv.starts_at, format: :human)} a été confirmé")
    end

    it "contains the ics" do
      cal = mail.find_first_mime_type("text/calendar")
      expect(cal.decoded).to match("UID:#{rdv.uuid}")
      expect(cal.decoded).to match("STATUS:CANCELLED") if rdv.cancelled?
    end

    it "contains the link to the rdv" do
      expect(mail.html_part.body.raw_source).to include("/users/rdvs/#{rdv.id}?invitation_token=12345")
    end
  end

  describe "#rdv_cancelled" do
    before { travel_to Time.zone.parse("2020-06-10 12:30") }

    let(:token) { "12345" }

    it "send mail to user" do
      rdv = create(:rdv)
      user = rdv.users.first
      mail = described_class.with(rdv: rdv, user: user, token: token).rdv_cancelled

      expect(mail.to).to eq([user.email])
      expect(mail.reply_to).to eq(["rdv+#{rdv.uuid}@reply.rdv-solidarites.fr"])
    end

    it "subject contains date of cancelled rdv" do
      organisation = build(:organisation, name: "Orga du coin")
      user = build(:user)
      rdv = create(:rdv, starts_at: Time.zone.parse("2020-06-15 12:30"), organisation: organisation, users: [user])
      mail = described_class.with(rdv: rdv, user: user, token: token).rdv_cancelled

      expect(mail.subject).to eq("RDV annulé le lundi 15 juin 2020 à 12h30 avec Orga du coin")
    end

    it "body contains cancelled confirmation with dateTime" do
      organisation = build(:organisation, name: "Orga du coin")
      user = build(:user)
      rdv = create(:rdv, starts_at: Time.zone.parse("2020-06-15 12:30"), organisation: organisation, users: [user])
      mail = described_class.with(rdv: rdv, user: user, token: token).rdv_cancelled

      expect(mail.html_part.body).to match("lundi 15 juin 2020 à 12h30")
    end

    it "body contains cancelled confirmation with motif's service name" do
      organisation = build(:organisation, name: "Orga du coin")
      user = build(:user)
      rdv = create(:rdv, starts_at: Time.zone.parse("2020-06-15 12:30"), organisation: organisation, users: [user])
      mail = described_class.with(rdv: rdv, user: user, token: token).rdv_cancelled

      expect(mail.html_part.body).to match(rdv.motif.service_name)
    end

    it "body contains link to book a new RDV" do
      organisation = build(:organisation, name: "Orga du coin")
      user = build(:user)
      rdv = create(:rdv, starts_at: Time.zone.parse("2020-06-15 12:30"), organisation: organisation, users: [user])
      mail = described_class.with(rdv: rdv, user: user, token: token).rdv_cancelled

      expected_url = prendre_rdv_url(\
        departement: rdv.organisation.departement_number, \
        motif_name_with_location_type: rdv.motif.name_with_location_type, \
        organisation_ids: [rdv.organisation_id], \
        address: rdv.address, \
        invitation_token: token, \
        host: Domain::RDV_SOLIDARITES.dns_domain_name
      )

      expect(mail.html_part.body).to have_link("Reprendre RDV", href: expected_url)
    end
  end

  describe "#rdv_upcoming_reminder" do
    let(:token) { "12345" }
    let!(:rdv) { create(:rdv, users: [user]) }
    let!(:user) { create(:user) }

    it "send mail to user" do
      mail = described_class.with(rdv: rdv, user: user, token: token).rdv_upcoming_reminder
      expect(mail.to).to eq([user.email])
      expect(mail.reply_to).to eq(["rdv+#{rdv.uuid}@reply.rdv-solidarites.fr"])
      expect(mail.html_part.body).to include("Nous vous rappellons que vous avez un RDV prévu")
      expect(mail.html_part.body.raw_source).to include("/users/rdvs/#{rdv.id}?invitation_token=12345")
    end
  end

  %i[rdv_created rdv_upcoming_reminder rdv_cancelled].each do |action|
    describe "using the agent domain's branding" do
      let(:rdv) { create(:rdv, motif: motif) }

      context "when motif's service is not conseiller_numerique" do
        let(:motif) { create(:motif, service: create(:service, :social)) }

        it "works" do
          mail = described_class.with(rdv: rdv, user: rdv.users.first, token: "12345").send(action)
          expect(mail.html_part.body.to_s).to include(%(src="/logo.png))
          expect(mail.html_part.body.to_s).to include(%(href="http://rdv-solidarites-test.localhost))
        end
      end

      context "when motif's service is conseiller_numerique" do
        let(:motif) { create(:motif, service: create(:service, :conseiller_numerique)) }

        # TODO: #rdv-inclusion-numerique-v1
        xit "works" do
          mail = described_class.with(rdv: rdv, user: rdv.users.first, token: "12345").send(action)
          expect(mail.html_part.body.to_s).to include(%(src="/logo_inclusion_numerique.png))
          expect(mail.html_part.body.to_s).to include(%(href="http://rdv-inclusion-numerique-test.localhost))
        end
      end
    end
  end
end
