RSpec.describe "Configure les préférences de signalisation d'usager en salle d'attente", type: :request do
  include Rails.application.routes.url_helpers

  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [organisation.territory]) }

  before { sign_in agent }

  it "show user in waiting room options" do
    get edit_admin_territory_rdv_fields_path(organisation.territory)
    expect(response).to be_successful
    expect(response.body).to include("Salle d&#39;attente")
    expect(response.body).to include("Envoyer un mail de notification à l&#39;agent")
    expect(response.body).to include("Modifier la couleur du rdv dans l&#39;agenda")
  end

  it "update user in waiting room options" do
    params = { territory: { enable_context_field: false, enable_waiting_room_mail_field: true, enable_waiting_room_color_field: true } }
    put admin_territory_rdv_fields_path(organisation.territory), params: params

    expect(response).to redirect_to(edit_admin_territory_rdv_fields_path(organisation.territory))
    territory = organisation.territory
    territory.reload
    expect(territory.enable_waiting_room_mail_field).to be(true)
    expect(territory.enable_waiting_room_color_field).to be(true)
  end
end
