RSpec.describe Users::RdvMailer, type: :mailer do
  describe "#rdv_created" do
    let(:rdv) { create(:rdv) }
    let(:user) { rdv.users.first }
    let(:token) { "12345" }
    let(:mail) { described_class.with(rdv: rdv, user: user, token: token).rdv_created }

    it "renders the headers" do
      expect(mail[:from].to_s).to eq(%("RDV Solidarités" <support@rdv-solidarites.fr>))
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

    it "contains the link to the rdv for cancellation without phone" do
      expect(mail.html_part.body.encoded).to match("Vous pouvez annuler votre rendez-vous</span> <strong>jusqu'à 4h avant celui-ci</strong> en cliquant sur le lien ci-dessous.")
      expect(mail.html_part.body.encoded).to match("Annuler le rendez-vous</a>")
      expect(mail.html_part.body.encoded).not_to match("en appelant au")
      expect(mail.html_part.body.raw_source).to include("/users/rdvs/#{rdv.id}?invitation_token=12345")
    end

    it "contains the link to the rdv for view only without phone" do
      rdv.motif.update(rdvs_editable_by_user: false)
      rdv.motif.update(rdvs_cancellable_by_user: false)
      mail = described_class.with(rdv: rdv, user: user, token: token).rdv_created
      expect(mail.html_part.body.encoded).not_to match("En cas de problème vous pouvez contacter le")
      expect(mail.html_part.body.encoded).to match("Voir le rendez-vous</a>")
    end

    it "contains the link to the rdv for cancellation with phone" do
      rdv.organisation.update(phone_number: "0601010101")
      mail = described_class.with(rdv: rdv, user: user, token: token).rdv_created
      expect(mail.html_part.body.encoded).to match("<span>Vous pouvez annuler votre rendez-vous</span> <strong>jusqu'à 4h avant celui-ci</strong>")
      expect(mail.html_part.body.encoded).to match("<span>en appelant au <a href=\"tel:0601010101\">0601010101</a> ou</span> en cliquant sur le lien ci-dessous")
      expect(mail.html_part.body.encoded).to match("Annuler le rendez-vous</a>")
    end

    it "contains the link to the rdv for view only with phone" do
      rdv.organisation.update(phone_number: "0601010101")
      rdv.motif.update(rdvs_editable_by_user: false)
      rdv.motif.update(rdvs_cancellable_by_user: false)
      mail = described_class.with(rdv: rdv, user: user, token: token).rdv_created
      expect(mail.html_part.body.encoded).to match("<span>En cas de problème vous pouvez contacter le <a href=\"tel:0601010101\">0601010101</a>")
      expect(mail.html_part.body.encoded).to match("Voir le rendez-vous</a>")
    end

    it "contains the link to the rdv for edit and cancellation with phone" do
      rdv.organisation.update(phone_number: "0601010101")
      rdv.update(created_by_type: "User")
      mail = described_class.with(rdv: rdv, user: user, token: token).rdv_created
      expect(mail.html_part.body.encoded).to match("<span>Vous pouvez annuler ou modifier votre rendez-vous</span> <strong>jusqu'à 4h avant celui-ci</strong>")
      expect(mail.html_part.body.encoded).to match("<span>en appelant au <a href=\"tel:0601010101\">0601010101</a> ou</span> en cliquant sur le lien ci-dessous")
      expect(mail.html_part.body.encoded).to match("Annuler ou modifier le rendez-vous</a>")
    end

  end

  describe "#rdv_updated" do
    let(:previous_starting_time) { 2.days.from_now }
    let(:new_starting_time) { 3.days.from_now }
    let(:new_lieu) { create(:lieu, name: "Stade de France", address: "rue du Stade, Paris, 75016") }
    let(:previous_lieu) { create(:lieu, name: "MJC Aix", address: "rue du Previous, Paris, 75016") }
    let(:rdv) { create(:rdv, lieu: new_lieu, starts_at: new_starting_time) }
    let(:user) { rdv.users.first }
    let(:token) { "12345" }

    before { travel_to(Time.zone.parse("2022-08-24 09:00:00")) }

    it "renders the headers" do
      mail = described_class.with(rdv: rdv, user: user, token: token).rdv_updated(starts_at: previous_starting_time, lieu_id: nil)
      expect(mail[:from].to_s).to eq(%("RDV Solidarités" <support@rdv-solidarites.fr>))
      expect(mail.to).to eq([user.email])
      expect(mail.reply_to).to eq(["rdv+#{rdv.uuid}@reply.rdv-solidarites.fr"])
    end

    it "indicates the previous and current values" do
      mail = described_class.with(rdv: rdv, user: user, token: token)
        .rdv_updated(starts_at: previous_starting_time, lieu_id: previous_lieu.id)

      previous_details = "Votre RDV qui devait avoir lieu le 26 août à 09:00 à l&#39;adresse MJC Aix (rue du Previous, Paris, 75016) a été modifié"
      expect(mail.html_part.body.to_s).to include(previous_details)

      # new details
      expect(mail.html_part.body.to_s).to include("samedi 27 août 2022 à 09h00")
      expect(mail.html_part.body.to_s).to include("Stade de France (rue du Stade, Paris, 75016)")
    end

    it "works when no lieu_id is passed" do
      mail = described_class.with(rdv: rdv, user: user, token: token)
        .rdv_updated(starts_at: previous_starting_time, lieu_id: nil)

      previous_details = "Votre RDV qui devait avoir lieu le 26 août à 09:00 a été modifié"
      expect(mail.html_part.body.to_s).to include(previous_details)
    end
  end

  describe "#rdv_cancelled" do
    before { travel_to Time.zone.parse("2020-06-10 12:30") }

    let(:token) { "12345" }

    it "send mail to user" do
      rdv = create(:rdv)
      user = rdv.users.first
      mail = described_class.with(rdv: rdv, user: user, token: token).rdv_cancelled

      expect(mail[:from].to_s).to eq(%("RDV Solidarités" <support@rdv-solidarites.fr>))
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
        host: Domain::RDV_SOLIDARITES.host_name
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
      expect(mail[:from].to_s).to eq(%("RDV Solidarités" <support@rdv-solidarites.fr>))
      expect(mail.to).to eq([user.email])
      expect(mail.reply_to).to eq(["rdv+#{rdv.uuid}@reply.rdv-solidarites.fr"])
      expect(mail.html_part.body).to include("Nous vous rappellons que vous avez un RDV prévu")
      expect(mail.html_part.body.raw_source).to include("/users/rdvs/#{rdv.id}?invitation_token=12345")
    end
  end

  %i[rdv_created rdv_upcoming_reminder rdv_cancelled].each do |action|
    describe "using the agent domain's branding" do
      let(:rdv) { create(:rdv, motif: motif, organisation: organisation) }
      let(:motif) do
        create(:motif, service: create(:service), organisation: organisation)
      end

      context "when the organisation uses the rdv_solidarites verticale" do
        let(:organisation) { create(:organisation, verticale: :rdv_solidarites) }

        it "works" do
          mail = described_class.with(rdv: rdv, user: rdv.users.first, token: "12345").send(action)
          expect(mail[:from].to_s).to eq(%("RDV Solidarités" <support@rdv-solidarites.fr>))
          expect(mail.html_part.body.to_s).to include(%(src="/logo_solidarites.png))
          expect(mail.html_part.body.to_s).to include(%(href="http://www.rdv-solidarites-test.localhost))
          expect(mail.html_part.body.to_s).to include(%(L’équipe RDV Solidarités))
        end
      end

      context "when the organisation uses the rdv_insertion verticale" do
        let(:organisation) { create(:organisation, verticale: :rdv_insertion) }

        it "works" do
          mail = described_class.with(rdv: rdv, user: rdv.users.first, token: "12345").send(action)
          expect(mail[:from].to_s).to eq(%("RDV Solidarités" <support@rdv-solidarites.fr>))
          expect(mail.html_part.body.to_s).to include(%(src="/logo_solidarites.png))
          expect(mail.html_part.body.to_s).to include(%(href="http://www.rdv-solidarites-test.localhost))
          expect(mail.html_part.body.to_s).to include(%(L’équipe RDV Solidarités))
        end
      end

      context "when the organisation uses the rdv_aide_numerique verticale" do
        let(:organisation) { create(:organisation, verticale: :rdv_aide_numerique) }

        it "works" do
          mail = described_class.with(rdv: rdv, user: rdv.users.first, token: "12345").send(action)
          expect(mail[:from].to_s).to eq(%("RDV Aide Numérique" <support@rdv-aide-numerique.fr>))
          expect(mail.html_part.body.to_s).to include(%(src="/logo_aide_numerique.png))
          expect(mail.html_part.body.to_s).to include(%(href="http://www.rdv-aide-numerique-test.localhost))
          expect(mail.html_part.body.to_s).to include(%(L’équipe RDV Aide Numérique))
        end
      end

      context "when the organisation uses the rdv_mairie verticale" do
        let(:organisation) { create(:organisation, verticale: :rdv_mairie) }

        it "works" do
          mail = described_class.with(rdv: rdv, user: rdv.users.first, token: "12345").send(action)
          expect(mail[:from].to_s).to eq(%(RDV Service Public <support@rdv-service-public.fr>))
          expect(mail.html_part.body.to_s).to include(%(src="/logo_rdv_service_public.png))
          expect(mail.html_part.body.to_s).to include(%(href="http://www.rdv-mairie-test.localhost))
          expect(mail.html_part.body.to_s).to include(%(L’équipe RDV Service Public))
        end
      end
    end
  end
end
