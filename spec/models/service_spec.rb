RSpec.describe Service, type: :model do
  describe "validations" do
    it "limits the length of #name to 2-60 characters" do
      expect(build(:service, name: "")).to be_invalid
      expect(build(:service, name: "a")).to be_invalid
      expect(build(:service, name: "aa")).to be_valid
      expect(build(:service, name: "aaa")).to be_valid
      expect(build(:service, name: "a" * 59)).to be_valid
      expect(build(:service, name: "a" * 60)).to be_valid
      expect(build(:service, name: "a" * 61)).to be_invalid
    end

    it "limits the length of #short_name to 2-40 characters" do
      expect(build(:service, name: "")).to be_invalid
      expect(build(:service, name: "a")).to be_invalid
      expect(build(:service, name: "aa")).to be_valid
      expect(build(:service, name: "aaa")).to be_valid
      expect(build(:service, short_name: "a" * 39)).to be_valid
      expect(build(:service, short_name: "a" * 40)).to be_valid
      expect(build(:service, short_name: "a" * 41)).to be_invalid
    end
  end

  describe "#pmi?" do
    it "returns false when social service" do
      expect(build(:service, :social).pmi?).to be false
    end

    it "returns true when pmi service" do
      expect(build(:service, :pmi).pmi?).to be true
    end
  end
end
