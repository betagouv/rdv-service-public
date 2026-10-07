FactoryBot.factories.each do |factory|
  RSpec.describe "The #{factory.name} factory" do
    stub_env_with(ALLOWED_WEBHOOK_HOSTS: "ALLOW_ALL_HOSTS")

    it "is valid" do
      expect(build(factory.name)).to be_valid
    end
  end
end
