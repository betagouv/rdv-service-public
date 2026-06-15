RSpec.describe Service, type: :model do
  describe "validations" do
    it "limits the length of #name to 2-60 characters" do
      expect(described_class.new(short_name: "Valide", name: nil)).to be_invalid
      expect(described_class.new(short_name: "Valide", name: "")).to be_invalid
      expect(described_class.new(short_name: "Valide", name: "a")).to be_invalid
      expect(described_class.new(short_name: "Valide", name: "aa")).to be_valid
      expect(described_class.new(short_name: "Valide", name: "aaa")).to be_valid
      expect(described_class.new(short_name: "Valide", name: "a" * 59)).to be_valid
      expect(described_class.new(short_name: "Valide", name: "a" * 60)).to be_valid
      expect(described_class.new(short_name: "Valide", name: "a" * 61)).to be_invalid

      expect(described_class.new(short_name: "Valide", name: "a").tap(&:validate).errors.full_messages).to include("Le nom du service doit contenir au moins 2 caractères.")
      expect(described_class.new(short_name: "Valide", name: "a" * 61).tap(&:validate).errors.full_messages).to include("Le nom du service ne doit pas dépasser 60 caractères.")
    end

    it "limits the length of #short_name to 2-40 characters" do
      expect(described_class.new(name: "Valide", short_name: "")).to be_invalid
      expect(described_class.new(name: "Valide", short_name: "a")).to be_invalid
      expect(described_class.new(name: "Valide", short_name: "aa")).to be_valid
      expect(described_class.new(name: "Valide", short_name: "aaa")).to be_valid
      expect(described_class.new(name: "Valide", short_name: "a" * 39)).to be_valid
      expect(described_class.new(name: "Valide", short_name: "a" * 40)).to be_valid
      expect(described_class.new(name: "Valide", short_name: "a" * 41)).to be_invalid

      expect(described_class.new(name: "Valide", short_name: "a").tap(&:validate).errors.full_messages).to include("Le nom raccourci pour les SMS doit contenir au moins 2 caractères.")
      expect(described_class.new(name: "Valide", short_name: "a" * 41).tap(&:validate).errors.full_messages).to include("Le nom raccourci pour les SMS ne doit pas dépasser 40 caractères.")
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
