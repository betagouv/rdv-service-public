RSpec.describe "Migration depuis RDV Aide Numérique vers RDV Service Public" do
  around { |example| perform_enqueued_jobs { example.run } }

  before do
    login_as agent_rdv_aide_num, scope: :agent
  end

  let!(:agent_rdv_aide_num) do
    create(:agent, first_name: "Camille", last_name: "Clavier", admin_role_in_organisations: [organisation_rdv_aide_num])
  end
  let(:organisation_rdv_aide_num) { create(:organisation, name: "France Service de Montreuil") }

  let!(:agent_rdv_sp) do
    create(:agent, first_name: "Camille", last_name: "Clavier", admin_role_in_organisations: rdv_sp_organisations)
  end
  let(:api_token) { create(:access_token, resource_owner_id: agent_rdv_sp.id, application: oauth_application) }
  let(:rdv_sp_organisations) { [] }

  let!(:oauth_application) { create(:oauth_application, name: "RDV Aide Numérique") }

  context "quand l'agent a deux organisations sur RDV SP" do
    let(:rdv_sp_organisations) { [organisation_rdv_sp1, organisation_rdv_sp2] }
    let!(:organisation_rdv_sp1) { create(:organisation, name: "France Service de Montreuil") }
    let!(:organisation_rdv_sp2) { create(:organisation, name: "CCAS de Montreuil") }

    let(:instance_export) do
      InstanceExport.create!(agent_id: agent_rdv_aide_num.id, api_token: api_token.plaintext_token, refresh_token: api_token.refresh_token, status: "oauth_connected")
    end

    stub_env_with(RDV_SERVICE_PUBLIC_OAUTH_BASE_URL: "http://localhost:#{Capybara.server_port}")

    it "lui permet de choisir vers laquelle il fait la migration", js: true do
      visit admin_organisation_instance_export_url(organisation_rdv_aide_num, instance_export.id, host: "www.rdv-aide-numerique-test.localhost")

      select "France Service de Montreuil", from: :destination_organisation_id

      click_on "Copier les données"

      expect(page).to have_content "Migration terminée !"

      expect(instance_export.reload.destination_organisation_id).to eq organisation_rdv_sp1.id
    end
  end

  context "quand l'agent a commencé une migration, mais s'est arrêté après la connexion OAuth" do
    let!(:instance_export) do
      InstanceExport.create!(
        agent_id: agent_rdv_aide_num.id,
        api_token: api_token.plaintext_token,
        refresh_token: api_token.refresh_token,
        status: "oauth_connected",
        source_organisation_id: organisation_rdv_aide_num.id
      )
    end

    stub_env_with(RDV_SERVICE_PUBLIC_OAUTH_BASE_URL: "http://rdv.gouv.localhost:1234")

    before do
      allow_any_instance_of(RdvServicePublicApiClient).to receive(:get).with("organisations").and_return({ "organisations" => [] }) # rubocop:disable RSpec/AnyInstance
    end

    it "lui permet de reprendre la migration depuis l'index" do
      visit admin_organisation_instance_exports_url(organisation_rdv_aide_num, host: "www.rdv-aide-numerique-test.localhost")
      click_on "Continuer la migration", match: :first
    end
  end
end
