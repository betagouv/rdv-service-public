RSpec.describe "Un agent peut ajouter des usagers à un RDV Collectif", js: true do
  # on a besoin de js:true ici pour faire fonctionner les selects d’usagers

  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent_noe) { create(:agent, first_name: "Noé", email: "noe@service.fr", service:, admin_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, :collectif, service:, organisation:, name: "Atelier Collectif") }
  let!(:lieu) { create(:lieu, organisation:) }
  let(:starts_at) { Time.zone.today.next_occurring(:wednesday).at(Tod::TimeOfDay.parse("09:00")) }
  let!(:rdv) { create(:rdv, :without_users, motif:, organisation:, agents: [agent_noe], lieu:, starts_at:) }

  describe "ajout d’un usager de l’orga courante" do
    let!(:user_celeste) { create(:user, first_name: "Céleste", last_name: "KHO", organisations: [organisation]) }

    specify do
      login_as(agent_noe, scope: :agent)
      visit root_path
      click_on "RDV collectifs"
      expect(page).to have_content("Atelier Collectif")
      click_on "Ajouter un participant"
      expect(page).to have_title("Ajouter un participant")
      expect(find("input[type=submit]")).to be_disabled
      add_user(user_celeste)
      expect(page).to have_content("Céleste KHO")
      expect(find("input[type=submit]")).not_to be_disabled
      click_on "Enregistrer"

      # aucun email n’est envoyé en cas de modification des usagers car on ne partage pas l’info sur les usagers
      # dans les emails ni les PJ ICS
      expect(rdv.reload.users).to eq([user_celeste])
      expect(open_email("noe@service.fr")).to be_nil
      # il n’y a pas non plus d’email envoyé si l’auteur de l’ajout de participant n’est pas l’agent du RDV
    end
  end

  describe "Ajout d’un usager qui appartient à plusieurs organisations" do
    let(:other_orga) { create(:organisation, territory: organisation.territory) }
    let!(:user_celeste) { create(:user, first_name: "Céleste", last_name: "KHO", organisations: [organisation, other_orga]) }

    specify do
      login_as(agent_noe, scope: :agent)

      visit root_path
      click_on "RDV collectifs"
      expect(page).to have_content("Atelier Collectif")
      click_on "Ajouter un participant"
      expect(page).to have_title("Ajouter un participant")
      add_user(user_celeste)
      click_on "Enregistrer"

      expect(rdv.reload.users).to eq([user_celeste])
      expect(open_email("noe@service.fr")).to be_nil
    end
  end

  describe "Injection d’un ID d’usager qui n’appartient pas à l’orga" do
    let!(:user) do
      create(:user, organisations: [organisation], first_name: "Francis", last_name: "Factice")
    end
    let(:organisation_from_other_territory) { create(:organisation, territory: create(:territory)) }
    let(:user_from_other_territory) do
      create(:user, organisations: [organisation_from_other_territory], first_name: "Gaston", last_name: "Bidon")
    end

    it "ne montre pas l’usager injecté sur la page" do
      login_as(agent_noe, scope: :agent)

      visit edit_admin_organisation_rdvs_collectif_path(organisation, rdv, add_user: [user.id])
      expect(page).to have_content("Francis")

      visit edit_admin_organisation_rdvs_collectif_path(organisation, rdv, add_user: [user_from_other_territory.id])
      expect(page).not_to have_content("Gaston")

      visit edit_admin_organisation_rdvs_collectif_path(organisation, rdv, add_user: [user.id, user_from_other_territory.id])
      expect(page).to have_content("Francis")
      expect(page).not_to have_content("Gaston")
    end
  end
end
