describe TransactionalSms::RdvCancelled, type: :service do
  let(:user) { build(:user) }
  let(:pmi) { build(:service, short_name: "PMI") }
  let(:motif) { build(:motif, service: pmi) }

  describe "#content" do
    context "with lieu phone number" do
      it "contains cancelled RDV's infos and lieu's phone number" do
        lieu = build(:lieu, phone_number: "0123456789")
        organisation = build(:organisation, phone_number: "9876543210")
        rdv = build(:rdv, motif: motif, organisation: organisation, lieu: lieu, starts_at: Time.zone.local(2021, 12, 10, 13, 10))
        expected_content = "RDV PMI vendredi 10/12 à 13h10 a été annulé\n"
        expected_content += "Appelez le 0123456789 "
        expected_content += "ou allez sur https://rdv-solidarites.fr pour reprendre RDV."
        expect(described_class.new(rdv, user).content).to eq(expected_content)
      end
    end

    context "with only organisation number" do
      it "contains cancelled RDV's infos" do
        lieu = build(:lieu, phone_number: nil)
        organisation = build(:organisation, phone_number: "9876543210")
        rdv = build(:rdv, motif: motif, organisation: organisation, lieu: lieu, starts_at: Time.zone.local(2021, 12, 10, 13, 10))
        expected_content = "RDV PMI vendredi 10/12 à 13h10 a été annulé\n"
        expected_content += "Appelez le 9876543210 "
        expected_content += "ou allez sur https://rdv-solidarites.fr pour reprendre RDV."
        expect(described_class.new(rdv, user).content).to eq(expected_content)
      end
    end

    context "with no phone number" do
      it "contains cancelled RDV's infos" do
        lieu = build(:lieu, phone_number: nil)
        organisation = build(:organisation, phone_number: nil)
        rdv = build(:rdv, motif: motif, organisation: organisation, lieu: lieu, starts_at: Time.zone.local(2021, 12, 10, 13, 10))
        expected_content = "RDV PMI vendredi 10/12 à 13h10 a été annulé\n"
        expected_content += "Allez sur https://rdv-solidarites.fr pour reprendre RDV."
        expect(described_class.new(rdv, user).content).to eq(expected_content)
      end
    end
  end
end
