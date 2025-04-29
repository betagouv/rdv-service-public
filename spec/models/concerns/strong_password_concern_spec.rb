RSpec.describe StrongPasswordConcern do
  describe ".generate" do
    it "génère des mots de passes valides" do
      3.times do
        password = described_class.generate
        obj = FactoryBot.build(:user, password:)
        obj.validate
        expect(obj).to be_valid
      end
    end
  end
end
