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

  context "when there is an old access token, and a more recent one for the same app and agent" do
    let!(:old_token) do
      Doorkeeper::AccessToken.create!(
        resource_owner_id: agent.id,
        application_id: oauth_application.id,
        created_at: 1.year.ago
      )
    end

    let!(:recent_token) do
      Doorkeeper::AccessToken.create!(
        resource_owner_id: agent.id,
        application_id: oauth_application.id,
        created_at: 1.week.ago
      )
    end

    it "deletes the old one and keeps the recent one" do
      described_class.new.perform
      expect(Doorkeeper::AccessToken.all).to eq [recent_token]
    end
  end

  context "when there are other tokens, but we still want to keep the old one" do
    let!(:token) do
      Doorkeeper::AccessToken.create!(
        resource_owner_id: agent.id,
        application_id: oauth_application.id,
        created_at: 1.year.ago
      )
    end

    # Ces autres tokens permettent de vérifier que le JOIN est correct
    let!(:token_for_other_agent) do
      Doorkeeper::AccessToken.create!(
        resource_owner_id: create(:agent).id,
        application: oauth_application,
        created_at: 1.week.ago
      )
    end

    let!(:token_for_other_application) do
      Doorkeeper::AccessToken.create!(
        resource_owner_id: agent.id,
        application: create(:oauth_application),
        created_at: 1.week.ago
      )
    end

    it "keeps it indefinitely, so that the client can keep on using the refresh token" do
      described_class.new.perform
      expect(Doorkeeper::AccessToken.all).to contain_exactly(token, token_for_other_agent, token_for_other_application)
    end
  end
end
