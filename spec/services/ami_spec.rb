# Cette spec sert de test pour tous les service objects liés à AMI pour tout réunir en un seul fichier
RSpec.describe Ami do
  stub_env_with(
    AMI_URL: "https://ami.test",
    AMI_PARTNER_ID: "dinum-rdvsp",
    AMI_PARTNER_SECRET: "test-secret"
  )

  let(:participation) { create(:participation, user: user) }
  let(:user) { create(:user) }

  before do
    AmiFranceConnectHash.create!(user: user, fc_hash: "test_ami_fc_hash")
    WebMock.stub_request(:put, "https://ami.test/api/v2/event")
  end

  it "permet de faire un appel à l'api d'AMI pour ajouter le rendez-vous à la liste des démarches en cours." do
    described_class.new(participation).create_event

    expect(WebMock).to(have_requested(:put, "https://ami.test/api/v2/event").with do |request|
      expect(request.headers).to include(
        "Authorization" => "Basic ZGludW0tcmR2c3A6dGVzdC1zZWNyZXQ=",
        "Content-Type" => "application/json"
      )

      expect(JSON.parse(request.body)["item_generic_status"]).to eq "new"
    end)
  end

  it "permet d'envoyer une notification quand le rendez-vous change" do
    described_class.new(participation).send_event_update_notification

    expect(WebMock).to(have_requested(:put, "https://ami.test/api/v2/event").with do |request|
      expect(JSON.parse(request.body)["content_body"]).to eq "Votre rendez-vous a été modifié."
    end)
  end

  it "permet d'envoyer une notification de rappel" do
    described_class.new(participation).send_reminder

    expect(WebMock).to(have_requested(:put, "https://ami.test/api/v2/event").with do |request|
      expect(JSON.parse(request.body)["content_body"]).to start_with "Nous vous rappelons que vous avez rendez-vous"
    end)
  end

  it "permet de fermer la démarche" do
    # Quand le rendez-vous a lieu, il faut fermer la démarche
    # On fait aussi cet appel si le rendez-vous est annulé (par l'agent ou l'usager) ou en cas de no-show.
    described_class.new(participation).close_event

    expect(WebMock).to(have_requested(:put, "https://ami.test/api/v2/event").with do |request|
      expect(JSON.parse(request.body)["item_generic_status"]).to eq "closed"
    end)
  end
end
