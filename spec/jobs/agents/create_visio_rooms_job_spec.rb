RSpec.describe Agents::CreateVisioRoomsJob do
  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:visio_motif) { create(:motif, organisation:, location_type: :visio) }
  let(:rooms_api_url) { "#{VisioNumerique::CreateRoom::DEFAULT_API_URL}/rooms/" }

  def create_visio_rdv(**attributes)
    create(:rdv, organisation:, motif: visio_motif, lieu: nil, **attributes)
  end

  before do
    stub_request(:post, rooms_api_url)
      .to_return(status: 200, body: { url: "https://visio.numerique.gouv.fr/salon" }.to_json, headers: { "Content-Type" => "application/json" })
  end

  it "crée un salon pour les RDV en visio à venir de l'organisation, y compris ceux des autres agents" do
    rdv_of_agent = create_visio_rdv(agents: [agent])
    rdv_of_colleague = create_visio_rdv

    described_class.perform_now(agent, "un-token")

    expect(rdv_of_agent.reload.visio_url_custom).to eq("https://visio.numerique.gouv.fr/salon")
    expect(rdv_of_colleague.reload.visio_url_custom).to eq("https://visio.numerique.gouv.fr/salon")
    expect(WebMock).to have_requested(:post, rooms_api_url).with(headers: { "Authorization" => "Bearer un-token" }).twice
  end

  it "ignore les RDV passés, annulés, déjà pourvus d'un salon, hors visio ou d'une autre organisation" do
    create_visio_rdv(starts_at: 2.days.ago)
    create_visio_rdv(status: "excused", cancelled_at: Time.zone.now)
    create_visio_rdv(visio_url_custom: "https://visio.numerique.gouv.fr/existant")
    create(:rdv, organisation:)
    other_organisation = create(:organisation)
    create(:rdv, organisation: other_organisation, motif: create(:motif, organisation: other_organisation, location_type: :visio), lieu: nil)

    described_class.perform_now(agent, "un-token")

    expect(WebMock).not_to have_requested(:post, rooms_api_url)
  end

  it "met à jour le RDV sans envoyer de notification" do
    rdv = create_visio_rdv(agents: [agent])

    expect { described_class.perform_now(agent, "un-token") }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
    expect(rdv.reload.visio_url_custom).to be_present
  end

  it "s'arrête dès que l'API renvoie une erreur" do
    stub_request(:post, rooms_api_url).to_return(status: 401, body: {}.to_json, headers: { "Content-Type" => "application/json" })
    rdvs = [create_visio_rdv, create_visio_rdv]

    described_class.perform_now(agent, "un-token-expire")

    expect(WebMock).to have_requested(:post, rooms_api_url).once
    expect(rdvs.map { _1.reload.visio_url_custom }).to all(be_nil)
  end

  context "quand l'agent a un jeton Menshen valide" do
    let(:agent) do
      create(:agent, basic_role_in_organisations: [organisation], menshen_access_token: "un-jeton-menshen", menshen_access_token_expires_at: 1.hour.from_now)
    end

    it "crée les salons avec le jeton Menshen plutôt qu'avec l'access token ProConnect" do
      create_visio_rdv(agents: [agent])

      described_class.perform_now(agent, "un-token")

      expect(WebMock).to have_requested(:post, rooms_api_url).with(headers: { "Authorization" => "Bearer un-jeton-menshen" }).once
    end

    it "crée les salons même sans access token ProConnect" do
      create_visio_rdv(agents: [agent])

      described_class.perform_now(agent, nil)

      expect(WebMock).to have_requested(:post, rooms_api_url).with(headers: { "Authorization" => "Bearer un-jeton-menshen" }).once
    end
  end

  context "quand la Visio est désactivée" do
    stub_env_with(VISIO_NUMERIQUE_DISABLED: "true")

    it "ne crée aucun salon" do
      create_visio_rdv

      described_class.perform_now(agent, "un-token")

      expect(WebMock).not_to have_requested(:post, rooms_api_url)
    end
  end
end
