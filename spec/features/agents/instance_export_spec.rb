RSpec.describe "Migration depuis RDV Aide Numérique vers RDV Service Public", js: true do
  around { |example| perform_enqueued_jobs { example.run } }

  context "quand l'agent a deux organisations sur RDV SP" do
    let(:organisation_rdv_aide_num) { create(:organisation, name: "France Service de Montreuil") }
    let!(:agent_rdv_aide_num) do
      create(:agent, first_name: "Camille", last_name: "Clavier", admin_role_in_organisations: [organisation_rdv_aide_num])
    end

    let!(:agent_rdv_sp) do
      create(:agent, first_name: "Camille", last_name: "Clavier",
                     admin_role_in_organisations: [organisation_rdv_sp1, organisation_rdv_sp2])
    end

    let!(:organisation_rdv_sp1) { create(:organisation, name: "France Service de Montreuil") }
    let!(:organisation_rdv_sp2) { create(:organisation, name: "CCAS de Montreuil") }

    let(:api_token) do
      create(:access_token, resource_owner_id: agent_rdv_sp.id, application: oauth_application)
    end
    let(:instance_export) do
      InstanceExport.create!(agent_id: agent_rdv_aide_num.id, api_token: api_token.plaintext_token, refresh_token: api_token.refresh_token)
    end

    let!(:oauth_application) { create(:oauth_application, name: "RDV Aide Numérique") }

    stub_env_with(RDV_SERVICE_PUBLIC_OAUTH_BASE_URL: "http://localhost:#{Capybara.server_port}")

    it "lui permet de choisir vers laquelle il fait la migration" do
      login_as agent_rdv_aide_num, scope: :agent
      visit edit_admin_organisation_instance_export_url(organisation_rdv_aide_num, instance_export.id, host: "www.rdv-aide-numerique-test.localhost")

      select "France Service de Montreuil", from: :destination_organisation_id

      click_on "Copier les données"

      expect(page).to have_content "Migration terminée !"

      expect(instance_export.reload.destination_organisation_id).to eq organisation_rdv_sp1.id
    end
  end
end
