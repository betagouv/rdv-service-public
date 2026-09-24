RSpec.describe MenshenExchangeTokenJob do
  let(:agent) { create(:agent) }

  it "stocke le jeton Menshen échangé sur l'agent" do
    allow(Menshen::ExchangeToken).to receive(:new)
      .with(subject_token: "fake proconnect access token")
      .and_return(instance_double(Menshen::ExchangeToken, call: { "access_token" => "fake menshen token", "expires_in" => 3600 }))

    freeze_time do
      described_class.perform_now(agent.id, "fake proconnect access token")

      expect(agent.reload.menshen_access_token).to eq("fake menshen token")
      expect(agent.menshen_access_token_expires_at).to eq(3600.seconds.from_now)
    end
  end

  context "quand l'agent n'existe plus" do
    it "abandonne le job sans le retenter" do
      agent.destroy!

      expect(Sentry).to receive(:capture_exception).with(instance_of(ActiveRecord::RecordNotFound))

      expect { perform_enqueued_jobs { described_class.perform_later(agent.id, "fake proconnect access token") } }
        .not_to raise_error
    end
  end
end
