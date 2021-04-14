describe Organisation, type: :model do
  describe "#contactable" do
    it "return nothing when no organisation" do
      expect(described_class.contactable).to be_empty
    end

    it "return organisation with phone number" do
      organisation = create(:organisation, phone_number: "01 02 03 04 05")
      create(:organisation, phone_number: nil)
      expect(described_class.contactable).to eq([organisation])
    end

    it "return organisation with a website" do
      organisation = create(:organisation, phone_number: nil, website: "https://pasdecalais.fr")
      create(:organisation, phone_number: nil, website: nil)
      expect(described_class.contactable).to eq([organisation])
    end

    it "return organisation with an email" do
      organisation = create(:organisation, phone_number: nil, website: nil, email: "aude@pasdecalais.fr")
      create(:organisation, phone_number: nil, website: nil, email: nil)
      expect(described_class.contactable).to eq([organisation])
    end
  end
end
