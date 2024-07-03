RSpec.describe Users::RdvSms, type: :service do
  describe "#rdv_created" do
    context "with a basic rdv" do
      subject { described_class.rdv_created(rdv, user, token).content }

      let(:organisation) { build(:organisation) }
      let(:pmi) { build(:service, short_name: "PMI") }
      let(:motif) { build(:motif, service: pmi) }
      let(:lieu) { build(:lieu, name: "MDS Centre", address: "10 rue d'ici, Paris, 75016") }
      let(:rdv) { build(:rdv, motif: motif, organisation: organisation, lieu: lieu, starts_at: Time.zone.local(2021, 12, 10, 13, 10), id: 123, name: "Ne Doit pas s'afficher") }
      let(:user) { build(:user) }
      let(:token) { "12345" }

      it do
        expect(subject).to include("RDV PMI vendredi 10/12 à 13h10")
        expect(subject).to include("MDS Centre (10 rue d'ici, Paris, 75016)")
        expect(subject).to include("Infos et annulation")
        expect(subject).to include("http://www.rdv-solidarites-test.localhost/r/123/12345")
        expect(subject).not_to include("Ne Doit pas s'afficher")
      end
    end

    context "with a collective rdv" do
      subject { described_class.rdv_created(rdv, user, token).content }

      let(:rdv_name) { "Super Atelier" }
      let(:rdv) { build(:rdv, :collectif, starts_at: Time.zone.local(2021, 12, 10, 13, 10), id: 123, name: rdv_name) }
      let(:user) { build(:user) }
      let(:token) { "12345" }

      it "contains rdv title" do
        expect(subject).to include("RDV #{rdv.service.name} : Super Atelier, vendredi 10/12 à 13h10.")
      end

      context "with a blank name" do
        let(:rdv_name) { "    " }

        it "contains rdv title but not the blank name" do
          expect(subject).to include("RDV #{rdv.service.name} vendredi 10/12 à 13h10.")
        end
      end

      context "when the rdv name is too long" do
        let(:rdv_name) { "Organiser ses fichiers et ses dossiers sur son ordinateur" }

        it "truncates it too avoid sending too many sms and costing too much money" do
          expect(subject).to include("RDV #{rdv.service.name} : Organiser ses fichiers et ses dossiers sur son ord..., vendredi 10/12 à 13h10.")
        end
      end
    end

    context "with a follow_up rdv" do
      it "contains referent name" do
        agent = create(:agent, first_name: "James", last_name: "Bond")
        user = create(:user, referent_agents: [agent])
        motif = create(:motif, follow_up: true)
        rdv = create(:rdv, motif: motif, users: [user], agents: [agent])
        token = "12345"

        content = described_class.rdv_created(rdv, user, token).content

        expect(content).to include("J. BOND")
      end
    end
  end

  describe "#rdv_updated" do
    subject { described_class.rdv_updated(rdv, user, token).content }

    let(:pmi) { build(:service, short_name: "PMI") }
    let(:motif) { build(:motif, service: pmi) }
    let(:organisation) { build(:organisation) }
    let(:lieu) { build(:lieu, name: "MDS Centre", address: "10 rue d'ici, Paris, 75016") }
    let(:rdv) { build(:rdv, motif: motif, organisation: organisation, lieu: lieu, starts_at: Time.zone.local(2021, 12, 10, 13, 10), id: 124) }
    let(:token) { "2345" }
    let(:user) { build(:user) }

    it do
      expect(subject).to include("RDV modifié: PMI vendredi 10/12 à 13h10")
      expect(subject).to include("MDS Centre (10 rue d'ici, Paris, 75016)")
      expect(subject).to include("Infos et annulation")
      expect(subject).to include("http://www.rdv-solidarites-test.localhost/r/124/2345")
    end
  end

  describe "#rdv_cancelled" do
    subject { described_class.rdv_cancelled(rdv, user, token).content }

    let(:pmi) { build(:service, short_name: "PMI") }
    let(:motif) { build(:motif, service: pmi) }
    let(:lieu) { nil }
    let(:rdv) { build(:rdv, motif: motif, organisation: organisation, lieu: lieu, starts_at: Time.zone.local(2021, 12, 10, 13, 10)) }
    let(:user) { build(:user) }
    let(:token) { "393939" }

    context "with lieu phone number" do
      let(:lieu) { build(:lieu, phone_number: "0123456789") }
      let(:organisation) { create(:organisation, phone_number: "0100000000") }

      it "contains cancelled RDV's infos and lieu's phone number" do
        expected_content = "RDV PMI vendredi 10/12 à 13h10 a été annulé.\n"
        expected_content += "Appelez le 0123456789 "
        expected_content += "ou allez sur http://www.rdv-solidarites-test.localhost/prdv?tkn=393939 pour reprendre RDV."
        expect(subject).to eq(expected_content)
      end
    end

    context "with only organisation number" do
      let(:lieu) { build(:lieu, phone_number: nil) }
      let(:organisation) { create(:organisation, phone_number: "0100000000") }

      it "contains cancelled RDV's infos" do
        expected_content = "RDV PMI vendredi 10/12 à 13h10 a été annulé.\n"
        expected_content += "Appelez le 0100000000 "
        expected_content += "ou allez sur http://www.rdv-solidarites-test.localhost/prdv?tkn=393939 pour reprendre RDV."
        expect(subject).to eq(expected_content)
      end
    end

    context "with no phone number" do
      let(:lieu) { build(:lieu, phone_number: nil) }
      let(:organisation) { create(:organisation, phone_number: nil) }

      it "contains cancelled RDV's infos" do
        expected_content = "RDV PMI vendredi 10/12 à 13h10 a été annulé.\n"
        expected_content += "Allez sur http://www.rdv-solidarites-test.localhost/prdv?tkn=393939 pour reprendre RDV."
        expect(subject).to eq(expected_content)
      end
    end

    context "without lieu and no organisation number" do
      let(:lieu) { nil }
      let(:organisation) { create(:organisation, phone_number: nil) }

      it "contains cancelled RDV's infos" do
        expected_content = "RDV PMI vendredi 10/12 à 13h10 a été annulé.\n"
        expected_content += "Allez sur http://www.rdv-solidarites-test.localhost/prdv?tkn=393939 pour reprendre RDV."
        expect(subject).to eq(expected_content)
      end
    end
  end

  describe "#rdv_upcoming_reminder" do
    subject { described_class.rdv_upcoming_reminder(rdv, user, token).content }

    let(:pmi) { build(:service, short_name: "PMI") }
    let(:motif) { build(:motif, service: pmi) }
    let(:lieu) { build(:lieu, name: "MDS Centre", address: "10 rue d'ici, Paris, 75016") }
    let(:organisation) { build(:organisation) }
    let(:rdv) { build(:rdv, motif: motif, organisation: organisation, lieu: lieu, starts_at: Time.zone.local(2021, 12, 10, 13, 10), id: 140) }
    let(:user) { build(:user) }
    let(:token) { "7777" }

    it do
      expect(subject).to include("Rappel RDV PMI le vendredi 10/12 à 13h10")
      expect(subject).to include("MDS Centre (10 rue d'ici, Paris, 75016)")
      expect(subject).to include("Infos et annulation")
      expect(subject).to include("http://www.rdv-solidarites-test.localhost/r/140/7777")
    end
  end

  describe "rdv footer" do
    subject { described_class.rdv_created(rdv, user, token).content }

    let(:user) { build(:user, address: "10 rue de Toulon, Lille, 5000") }
    let(:token) { "12345" }

    describe "depending on motif" do
      let(:rdv) { build(:rdv, motif: motif, users: [user], starts_at: 5.days.from_now, id: 140) }

      context "when regular Rdv" do
        let(:motif) { build(:motif, :at_public_office) }

        it { is_expected.to include(rdv.address) }
      end

      context "when Rdv is at home" do
        let(:motif) { build(:motif, :at_home) }

        it do
          expect(subject).to include("RDV à votre domicile")
        end
      end

      context "when Rdv is by phone" do
        let(:motif) { build(:motif, :by_phone) }

        it do
          expect(subject).to include("RDV téléphonique")
          expect(subject).to include(rdv.address)
        end
      end

      context "when rdv is by visio" do
        let(:motif) { build(:motif, location_type: :visio) }

        it do
          expect(subject).to include("RDV par visioconférence")
          expect(subject).to include(rdv.address)
        end
      end

      context "if we add a new location type without adding the location text" do
        it "would raise an error in this block" do
          Motif.location_types.each_value do |location_type|
            motif = build(:motif, location_type: location_type)
            rdv = build(:rdv, motif: motif, users: [user], starts_at: 5.days.from_now, id: 1)

            described_class.rdv_created(rdv, user, token).content
          end
        end
      end
    end

    describe "depending on phone" do
      let(:rdv) { build(:rdv, lieu: lieu, organisation: organisation, users: [user], starts_at: 5.days.from_now, id: 140) }
      let(:lieu) { build(:lieu, phone_number: lieu_phone_number) }
      let(:organisation) { create(:organisation, phone_number: organisation_phone_number) }

      context "when both have a phone number" do
        let(:lieu_phone_number) { "0123456789" }
        let(:organisation_phone_number) { "0987654321" }

        it { expect(subject).to include(" / 0123456789") }
      end

      context "when only organisation has a phone number" do
        let(:lieu_phone_number) { nil }
        let(:organisation_phone_number) { "0987654321" }

        it { expect(subject).to include(" / 0987654321") }
      end

      context "when none have a phone number" do
        let(:lieu_phone_number) { nil }
        let(:organisation_phone_number) { nil }

        it { expect(subject).not_to include(" / ") }
      end
    end
  end
end
