RSpec.describe Rdvs::CreateVisioRoomJob do
  let(:organisation) { create(:organisation) }
  let(:visio_motif) { create(:motif, organisation:, location_type: :visio) }
  let(:agent_without_token) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:agent_with_token) do
    create(:agent, basic_role_in_organisations: [organisation], menshen_access_token: "un-jeton-menshen", menshen_access_token_expires_at: 1.hour.from_now)
  end
  let(:rooms_api_url) { "#{VisioNumerique::CreateRoom::DEFAULT_API_URL}/rooms/" }

  before do
    stub_request(:post, rooms_api_url)
      .to_return(status: 200, body: { url: "https://visio.numerique.gouv.fr/salon" }.to_json, headers: { "Content-Type" => "application/json" })
  end

  def create_visio_rdv(**attributes)
    create(:rdv, organisation:, motif: visio_motif, lieu: nil, **attributes)
  end

  it "crée le salon avec le jeton Menshen d'un des agents du RDV, sans notification" do
    rdv = create_visio_rdv(agents: [agent_without_token, agent_with_token])

    expect { described_class.perform_now(rdv) }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)

    expect(rdv.reload.visio_url_custom).to eq("https://visio.numerique.gouv.fr/salon")
    expect(WebMock).to have_requested(:post, rooms_api_url).with(headers: { "Authorization" => "Bearer un-jeton-menshen" }).once
  end

  it "ne fait rien si aucun agent du RDV n'a de jeton Menshen valide" do
    expired_agent = create(:agent, basic_role_in_organisations: [organisation], menshen_access_token: "expire", menshen_access_token_expires_at: 1.minute.ago)
    rdv = create_visio_rdv(agents: [agent_without_token, expired_agent])

    described_class.perform_now(rdv)

    expect(WebMock).not_to have_requested(:post, rooms_api_url)
  end

  it "ne fait rien si le RDV a déjà un salon ou a été annulé entre-temps" do
    rdv_with_room = create_visio_rdv(agents: [agent_with_token], visio_url_custom: "https://visio.numerique.gouv.fr/existant")
    cancelled_rdv = create_visio_rdv(agents: [agent_with_token], status: "excused", cancelled_at: Time.zone.now)

    described_class.perform_now(rdv_with_room)
    described_class.perform_now(cancelled_rdv)

    expect(WebMock).not_to have_requested(:post, rooms_api_url)
  end

  it "laisse le RDV sans salon si l'API renvoie une erreur" do
    stub_request(:post, rooms_api_url).to_return(status: 401, body: {}.to_json, headers: { "Content-Type" => "application/json" })
    rdv = create_visio_rdv(agents: [agent_with_token])

    described_class.perform_now(rdv)

    expect(rdv.reload.visio_url_custom).to be_nil
  end
end
