# frozen_string_literal: true

describe Users::RdvSms, type: :service do
  describe "#rdv_created" do
    context "with a basic rdv" do
      subject { described_class.rdv_created(rdv, user).content }

      let(:pmi) { build(:service, short_name: "PMI") }
      let(:motif) { build(:motif, service: pmi) }
      let(:lieu) { build(:lieu, name: "MDS Centre", address: "10 rue d'ici") }
      let(:rdv) { build(:rdv, motif: motif, lieu: lieu, starts_at: Time.zone.local(2021, 12, 10, 13, 10)) }
      let(:user) { build(:user) }

      it do
        expect(subject).to include("RDV PMI vendredi 10/12 à 13h10")
        expect(subject).to include("MDS Centre (10 rue d'ici)")
        expect(subject).to include("Infos et annulation")
      end
    end

    context "with a follow_up rdv" do
      it "contains referent name" do
        agent = create(:agent, first_name: "James", last_name: "Bond")
        user = create(:user, agents: [agent])
        motif = create(:motif, follow_up: true)
        rdv = create(:rdv, motif: motif, users: [user], agents: [agent])

        content = described_class.rdv_created(rdv, user).content

        expect(content).to include("J. Bond")
      end
    end
  end

  describe "#rdv_date_updated" do
    subject { described_class.rdv_date_updated(rdv, user).content }

    let(:pmi) { build(:service, short_name: "PMI") }
    let(:motif) { build(:motif, service: pmi) }
    let(:lieu) { build(:lieu, name: "MDS Centre", address: "10 rue d'ici") }
    let(:rdv) { build(:rdv, motif: motif, lieu: lieu, starts_at: Time.zone.local(2021, 12, 10, 13, 10)) }
    let(:user) { build(:user) }

    it do
      expect(subject).to include("RDV modifié: PMI vendredi 10/12 à 13h10")
      expect(subject).to include("MDS Centre (10 rue d'ici)")
      expect(subject).to include("Infos et annulation")
    end
  end

  describe "#rdv_cancelled" do
    subject { described_class.rdv_cancelled(rdv, user).content }

    let(:pmi) { build(:service, short_name: "PMI") }
    let(:motif) { build(:motif, service: pmi) }
    let(:rdv) { build(:rdv, motif: motif, organisation: organisation, lieu: lieu, starts_at: Time.zone.local(2021, 12, 10, 13, 10)) }
    let(:user) { build(:user) }

    context "with lieu phone number" do
      let(:lieu) { build(:lieu, phone_number: "0123456789") }
      let(:organisation) { create(:organisation, phone_number: "0100000000") }

      it "contains cancelled RDV's infos and lieu's phone number" do
        expected_content = "RDV PMI vendredi 10/12 à 13h10 a été annulé\n"
        expected_content += "Appelez le 0123456789 "
        expected_content += "ou allez sur https://rdv-solidarites.fr pour reprendre RDV."
        expect(subject).to eq(expected_content)
      end
    end

    context "with only organisation number" do
      let(:lieu) { build(:lieu, phone_number: nil) }
      let(:organisation) { create(:organisation, phone_number: "0100000000") }

      it "contains cancelled RDV's infos" do
        expected_content = "RDV PMI vendredi 10/12 à 13h10 a été annulé\n"
        expected_content += "Appelez le 0100000000 "
        expected_content += "ou allez sur https://rdv-solidarites.fr pour reprendre RDV."
        expect(subject).to eq(expected_content)
      end
    end

    context "with no phone number" do
      let(:lieu) { build(:lieu, phone_number: nil) }
      let(:organisation) { create(:organisation, phone_number: nil) }

      it "contains cancelled RDV's infos" do
        expected_content = "RDV PMI vendredi 10/12 à 13h10 a été annulé\n"
        expected_content += "Allez sur https://rdv-solidarites.fr pour reprendre RDV."
        expect(subject).to eq(expected_content)
      end
    end

    context "without lieu and no organisation number" do
      let(:lieu) { nil }
      let(:organisation) { create(:organisation, phone_number: nil) }

      it "contains cancelled RDV's infos" do
        expected_content = "RDV PMI vendredi 10/12 à 13h10 a été annulé\n"
        expected_content += "Allez sur https://rdv-solidarites.fr pour reprendre RDV."
        expect(subject).to eq(expected_content)
      end
    end
  end

  describe "#rdv_upcoming_reminder" do
    subject { described_class.rdv_upcoming_reminder(rdv, user).content }

    let(:pmi) { build(:service, short_name: "PMI") }
    let(:motif) { build(:motif, service: pmi) }
    let(:lieu) { build(:lieu, name: "MDS Centre", address: "10 rue d'ici") }
    let(:rdv) { build(:rdv, motif: motif, lieu: lieu, starts_at: Time.zone.local(2021, 12, 10, 13, 10)) }
    let(:user) { build(:user) }

    it do
      expect(subject).to include("Rappel RDV PMI le vendredi 10/12 à 13h10")
      expect(subject).to include("MDS Centre (10 rue d'ici)")
      expect(subject).to include("Infos et annulation")
    end
  end

  describe "rdv footer" do
    subject { described_class.rdv_created(rdv, user).content }

    let(:user) { build(:user, address: "10 rue de Toulon, Lille") }

    describe "depending on motif" do
      let(:rdv) { build(:rdv, motif: motif, users: [user], starts_at: 5.days.from_now) }

      context "when regular Rdv" do
        let(:motif) { build(:motif, :at_public_office) }

        it { is_expected.to include(rdv.address) }
      end

      context "when Rdv is at home" do
        let(:motif) { build(:motif, :at_home) }

        it do
          expect(subject).to include("RDV à domicile")
          expect(subject).to include(rdv.address)
        end
      end

      context "when Rdv is by phone" do
        let(:motif) { build(:motif, :by_phone) }

        it do
          expect(subject).to include("RDV Téléphonique")
          expect(subject).to include(rdv.address)
        end
      end
    end

    describe "depending on phone" do
      let(:rdv) { build(:rdv, lieu: lieu, organisation: organisation, users: [user], starts_at: 5.days.from_now) }
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
