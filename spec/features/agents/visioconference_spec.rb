RSpec.describe "Les agents peuvent organiser des rdv par visioconférence" do
  let!(:organisation) { organisations(:default_org) }
  let(:service) { create(:service) }

  let(:agent) do
    create(:agent, admin_role_in_organisations: [organisation], services: [service])
  end

  before do
    organisation.territory.update(services: [service])
    login_as(agent, scope: :agent)
  end

  it "adds validation when trying to create a rdv without email or phone number", js: true do
    motif = create(:motif, organisation: organisation, location_type: :visio, name: "Accompagnement RSA")

    visit new_admin_organisation_rdv_wizard_step_path(organisation_id: organisation.id)
    select(motif.name, from: "Motif du rendez-vous")
    click_button("Continuer")

    click_link("Ajouter un usager")

    # create user with mail
    fill_in :user_first_name, with: "Francis"
    fill_in :user_last_name, with: "Factice"
    expect(page).to have_selector(".user_email")
    click_button("Enregistrer")

    click_button("Continuer")
    expect(page).to have_content "Vous devez indiquer un numéro de téléphone mobile ou une adresse email pour que l'usager puisse recevoir le lien de visioconférence."
    find(".fr-icon-edit-line").click
    fill_in "Email", with: "francis@factice.org"
    click_button "Enregistrer"

    expect(page).to have_content "francis@factice.org" # pour attendre la requête ajax d'enregistrement de l'usager
    click_button "Continuer"
    expect(page).to have_content "Commence à"
  end
end
