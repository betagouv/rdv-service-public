RSpec.describe CronJob::DestroyOldOauthObjects do
  let(:oauth_application) { create(:oauth_application) }
  let(:agent) { create(:agent) }

  context "when there is only one access token for this user and this application" do
    let!(:token) do
      Doorkeeper::AccessToken.create!(
        resource_owner_id: agent.id,
        application_id: oauth_application.id,
        created_at: 1.year.ago
      )
    end

    it "keeps it indefinitely, so that the client can keep on using the refresh token" do
      described_class.new.perform
      expect(Doorkeeper::AccessToken.first).to eq token
    end
  end
end
