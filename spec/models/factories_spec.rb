FactoryBot.factories.each do |factory|
  RSpec.describe "The #{factory.name} factory" do
    it "is valid" do
      expect(build(factory.name)).to be_valid
    end
  end
end
