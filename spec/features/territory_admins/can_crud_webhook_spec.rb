RSpec.describe "territory admin can crud webhooks endpoints" do
  stub_env_with(ALLOWED_WEBHOOK_HOSTS: "ALLOW_ALL_HOSTS")

  let(:territory) { create(:territory) }
  let!(:organisation) { create(:organisation, territory: territory) }
  let(:agent) do
    create(:agent, role_in_territories: [territory])
  end

  before do
    create(:agent_territorial_access_right, agent: agent, territory: territory)
    login_as(agent, scope: :agent)
    visit admin_territory_path(id: territory.id)
  end

  it "works", js: true do
    # Create
    click_on "Webhook"
    click_on "Ajouter"
    select(organisation.name, from: "webhook_endpoint_organisation_id")
    fill_in("URL de destination", with: "https://webhook.test.com")
    fill_in("Clé privée", with: "XSECRET")
    click_on "Enregistrer"
    expect(page).to have_content organisation.name
    expect(page).to have_content "https://webhook.test.com"

    # Edit
    click_on "Modifier"
    fill_in("URL de destination", with: "https://webhook.test2.com")
    click_on "Enregistrer"
    expect(page).to have_content organisation.name
    expect(page).to have_content "https://webhook.test2.com"
    # Check that the secret didnt change
    expect(organisation.reload.webhook_endpoints.first.secret).to eq("XSECRET")

    # Delete
    accept_confirm do
      click_link "Supprimer"
    end
    expect(page).not_to have_content organisation.name
    expect(organisation.reload.webhook_endpoints.count).to eq(0)
  end

  context "quand le domaine de l'URL n'est pas dans la liste des domaines autorisé" do
    stub_env_with(ALLOWED_WEBHOOK_HOSTS: "webhook.test.com")

    it "affiche une erreur invitant à nous contacter" do
      click_on "Webhook"
      click_on "Ajouter"
      select(organisation.name, from: "webhook_endpoint_organisation_id")
      fill_in("URL de destination", with: "https://exfiltration.example.com/webhook")
      fill_in("Clé privée", with: "XSECRET")
      click_on "Enregistrer"
      expect(page).to have_content("« exfiltration.example.com » ne fait pas partie des domaines autorisés pour les webhooks. Contactez-nous pour ajouter votre domaine.")
      expect(organisation.reload.webhook_endpoints).to be_empty
    end
  end

  it "has correct permissions for other territories" do
    other_territory = create(:territory)
    visit admin_territory_webhook_endpoints_path(territory_id: other_territory.id)
    expect(page).to have_content "Vous n’avez pas les droits suffisants pour accéder à cette page ou effectuer cette action"
  end
end
