# frozen_string_literal: true

describe TransactionalSms::RdvCancelled, type: :service do
  describe "#content" do
    subject { described_class.new(OpenStruct.new(rdv.payload(:update)), user).content }

    let(:pmi) { build(:service, short_name: "PMI") }
    let(:motif) { build(:motif, service: pmi) }
    let(:rdv) { build(:rdv, motif: motif, organisation: organisation, lieu: lieu, starts_at: Time.zone.local(2021, 12, 10, 13, 10)) }
    let(:user) { build(:user) }

    context "with lieu phone number" do
      let(:lieu) { build(:lieu, phone_number: "0123456789") }
      let(:organisation) { build(:organisation, phone_number: "9876543210") }

      it "contains cancelled RDV's infos and lieu's phone number" do
        expected_content = "RDV PMI vendredi 10/12 à 13h10 a été annulé\n"
        expected_content += "Appelez le 0123456789 "
        expected_content += "ou allez sur https://rdv-solidarites.fr pour reprendre RDV."
        expect(subject).to eq(expected_content)
      end
    end

    context "with only organisation number" do
      let(:lieu) { build(:lieu, phone_number: nil) }
      let(:organisation) { build(:organisation, phone_number: "9876543210") }

      it "contains cancelled RDV's infos" do
        expected_content = "RDV PMI vendredi 10/12 à 13h10 a été annulé\n"
        expected_content += "Appelez le 9876543210 "
        expected_content += "ou allez sur https://rdv-solidarites.fr pour reprendre RDV."
        expect(subject).to eq(expected_content)
      end
    end

    context "with no phone number" do
      let(:lieu) { build(:lieu, phone_number: nil) }
      let(:organisation) { build(:organisation, phone_number: nil) }

      it "contains cancelled RDV's infos" do
        expected_content = "RDV PMI vendredi 10/12 à 13h10 a été annulé\n"
        expected_content += "Allez sur https://rdv-solidarites.fr pour reprendre RDV."
        expect(subject).to eq(expected_content)
      end
    end

    context "without lieu and no organisation number" do
      let(:lieu) { nil }
      let(:organisation) { build(:organisation, phone_number: nil) }

      it "contains cancelled RDV's infos" do
        expected_content = "RDV PMI vendredi 10/12 à 13h10 a été annulé\n"
        expected_content += "Allez sur https://rdv-solidarites.fr pour reprendre RDV."
        expect(subject).to eq(expected_content)
      end
    end
  end
end
