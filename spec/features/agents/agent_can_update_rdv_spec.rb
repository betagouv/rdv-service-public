RSpec.describe "Agent can update a RDV", js: true do
  let!(:organisation) { create(:organisation) }
  let(:rdv) do
    create(:rdv, organisation: organisation, motif: motif, agents: [agent], lieu: lieu)
  end
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, first_name: "Alain", last_name: "Tiptop", service: service, basic_role_in_organisations: [organisation]) }

  let!(:motif) { create(:motif, service: service, organisation: organisation) }
  let!(:lieu) { create(:lieu, organisation: organisation) }

  before do
    stub_netsize_ok
    login_as(agent, scope: :agent)
  end

  it "update existing RDV with single_use lieu" do
    visit edit_admin_organisation_rdv_path(organisation, rdv)
    click_link("Définir un lieu ponctuel.")
    fill_in "Nom", with: "Café de la gare"
    fill_in "Adresse", with: "3 Place de la Gare, Strasbourg, 67000"
    page.execute_script("document.querySelector('input#rdv_lieu_attributes_latitude').value = '48.583844'")
    page.execute_script("document.querySelector('input#rdv_lieu_attributes_longitude').value = 7.735253")
    click_button "Enregistrer"

    expect(page).to have_content("Café de la gare")
    expect(page).to have_content("3 Place de la Gare, Strasbourg, 67000")
    expect(page).to have_selector(".badge-info", text: /Ponctuel/)
  end

  it "update existing RDV with existing lieu" do
    lieu_ponctuel = create(:lieu, organisation: organisation, availability: :single_use)
    rdv = create(:rdv, organisation: organisation, motif: motif, agents: [agent], lieu: lieu_ponctuel)

    visit edit_admin_organisation_rdv_path(organisation, rdv)

    click_link("Choisir un lieu existant.")
    select(lieu.full_name, from: "rdv_lieu_id")
    click_button "Enregistrer"

    expect(page).to have_content(lieu.full_name)
    expect(page).not_to have_selector(".badge-info", text: /Ponctuel/)
  end

  describe "adding users" do
    context "when injecting the id of a user that isn't visible to the agent" do
      let(:user_from_other_territory) do
        create(:user, organisations: [create(:organisation)])
      end

      it "doesn't show the user's information" do
        visit edit_admin_organisation_rdv_path(organisation, rdv, add_user: [user_from_other_territory.id])
        expect(page).not_to have_content(user_from_other_territory.full_name)
      end
    end
  end

  context "mise à jour vers un motif d’une autre organisation", js: true do
    let!(:other_motif) { create(:motif, name: "Dȋner aux chandelles", organisation: create(:organisation)) }

    it "empêche le changement" do
      visit edit_admin_organisation_rdv_path(organisation, rdv)
      js = <<~JS
        var selectElt = document.querySelector('select#rdv_motif_id');
        selectElt.options[selectElt.selectedIndex].value = "#{other_motif.id}";
        selectElt.removeAttribute('disabled');
      JS
      page.execute_script(js)
      click_button "Enregistrer"
      expect(rdv.reload.motif).to eq(motif)
      expect(page).not_to have_content("Dȋner aux chandelles")
    end
  end
end
