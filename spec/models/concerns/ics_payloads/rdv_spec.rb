RSpec.describe IcsPayloads::Rdv, type: :service do
  describe "#payload" do
    %i[name ical_uid summary ends_at description location].each do |key|
      it "return an hash with key #{key}" do
        user = build(:user)
        rdv = build(:rdv, users: [user])
        expect(rdv.payload).to have_key(key)
      end
    end

    describe ":attachement_filename" do
      let(:user) { build(:user) }
      let(:rdv) { build(:rdv, users: [user], starts_at: Time.zone.parse("20201123 15h50")) }

      it { expect(rdv.payload[:attachement_filename]).to eq("rdv-#{rdv.motif.name.parameterize}-2020-11-23-15h50.ics") }
    end

    describe ":starts_at" do
      let(:user) { build(:user) }
      let(:starts_at) { Time.zone.parse("20201123 15h50") }
      let(:rdv) { build(:rdv, users: [user], starts_at: starts_at) }

      it { expect(rdv.payload[:starts_at]).to eq(starts_at) }
    end

    describe ":ends_at" do
      let(:user) { build(:user) }
      let(:starts_at) { Time.zone.parse("20201123 15h50") }
      let(:rdv) { build(:rdv, users: [user], starts_at: Time.zone.parse("20201123 15h50"), duration_in_min: 10) }

      it { expect(rdv.payload[:ends_at]).to eq(starts_at + 10.minutes) }
    end

    describe ":description" do
      let(:user) { build(:user) }
      let(:agent) { build(:agent) }
      let(:rdv) { create(:rdv, users: [user], agents: [agent]) }

      it "provides a link to the RDV index for users" do
        expect(rdv.payload[:description]).to eq("Infos et annulation: http://www.rdv-solidarites-test.localhost/r")
      end

      context "with a visio motif" do
        let(:rdv) { build(:rdv, users: [user], motif: build(:motif, location_type: :visio), uuid: 123) }

        it "indicates the location type" do
          expect(rdv.payload[:description]).to start_with "RDV par visioconférence"
        end
      end

      context "when sending to an agent" do
        it "provides a link to the RDV in the agent interface" do
          description = "Voir sur RDV Solidarités: http://www.rdv-solidarites-test.localhost/admin/organisations/#{rdv.organisation_id}/rdvs/#{rdv.id}"
          expect(rdv.payload(nil, agent)[:description]).to eq(description)
        end

        context "when there is a link to a dossier in an external app" do
          before do
            create(:rdv_plan, rdv: rdv, dossier_url: "http://demarches-simplifies.test/exemple", oauth_application:)
          end

          let(:oauth_application) { create(:oauth_application, name: "Démarches Simplifiées") }

          it "provides the link in the description" do
            expect(rdv.payload(nil, agent)[:description]).to include("Voir sur Démarches Simplifiées: http://demarches-simplifies.test/exemple")
          end
        end
      end
    end

    describe ":location" do
      let(:user) { build(:user) }

      context "with a phone motif" do
        let(:rdv) { build(:rdv, users: [user], motif: build(:motif, :by_phone)) }

        it { expect(rdv.payload[:location]).to be_nil }
      end

      context "without a phone motif" do
        let(:rdv) { build(:rdv, users: [user], motif: build(:motif, :public_office), lieu: build(:lieu, address: "17 rue de l'adresse, Paris, 75016")) }

        it { expect(rdv.payload[:location]).to eq("17 rue de l'adresse, Paris, 75016") }
      end

      context "with a visio motif" do
        let(:rdv) { build(:rdv, users: [user], motif: build(:motif, location_type: :visio), uuid: 123) }

        it "shows the link to the visio" do
          expect(rdv.payload[:location]).to eq "https://webconf.numerique.gouv.fr/RdvServicePublic"
        end
      end
    end

    describe ":ical_uid" do
      let(:user) { create(:user) }
      let(:rdv) { create(:rdv, users: [user]) }

      it { expect(rdv.payload[:ical_uid]).to eq(rdv.uuid) }
    end

    describe ":summary" do
      let(:user) { build(:user, first_name: "Ethan", last_name: "DUVAL") }
      let(:rdv) { build(:rdv, users: [user], motif: build(:motif, name: "Consultation")) }

      it { expect(rdv.payload[:summary]).to eq("RDV Consultation") }
    end
  end
end
