RSpec.describe "Agent can update a RDV", js: true do
  let(:territory) { create(:territory) }
  let!(:organisation) { create(:organisation, territory:) }
  let(:rdv) do
    create(:rdv, organisation: organisation, motif: motif, agents: [agent_shiraz], lieu: lieu, starts_at:, ends_at:)
  end
  let!(:agent_shiraz) { create(:agent, first_name: "Shiraz", last_name: "NADIR", email: "shiraz@angouleme.fr", basic_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, organisation: organisation) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let(:starts_at) { 1.hour.from_now }
  let(:ends_at) { starts_at + 1.hour }

  before do
    stub_netsize_ok
    login_as(agent_shiraz, scope: :agent)
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
    perform_enqueued_jobs
    open_email "shiraz@angouleme.fr"
    expect(current_email).not_to be_nil
    expect(current_email.subject).to match(/RDV .* modifié/)
  end

  it "update existing RDV with existing lieu" do
    lieu_ponctuel = create(:lieu, organisation: organisation, availability: :single_use)
    rdv = create(:rdv, organisation: organisation, motif: motif, agents: [agent_shiraz], lieu: lieu_ponctuel)

    visit edit_admin_organisation_rdv_path(organisation, rdv)

    click_link("Choisir un lieu existant.")
    select(lieu.full_name, from: "rdv_lieu_id")
    click_button "Enregistrer"

    expect(page).to have_content(lieu.full_name)
    expect(page).not_to have_selector(".badge-info", text: /Ponctuel/)
  end

  it "works when the lieu has been disabled" do
    lieu_disabled = create(:lieu, organisation: organisation, availability: :disabled)
    rdv = create(:rdv, organisation: organisation, motif: motif, agents: [agent_shiraz], lieu: lieu_disabled, starts_at: 3.days.ago)

    visit edit_admin_organisation_rdv_path(organisation, rdv)

    click_on "Enregistrer"
    expect(page).to have_content("Ce rendez-vous a une date située dans le passé")
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

  context "ajout d’un agent au RDV" do
    let!(:agent_jungyoon) { create(:agent, first_name: "Jung Yoon", last_name: "Han", email: "jungyoon@angouleme.fr", basic_role_in_organisations: [organisation]) }

    it "envoie un email à l’agent ajouté", skip: "cf PR #5399" do # rubocop:disable RSpec/Pending
      visit edit_admin_organisation_rdv_path(organisation, rdv)
      select("Jung Yoon HAN (Urbanisme)", from: "rdv_agent_ids")
      click_button "Enregistrer"

      expect(page).to have_content("Jung Yoon HAN (Urbanisme)")
      expect(page).to have_content("Shiraz NADIR (Urbanisme)")
      perform_enqueued_jobs
      open_email "shiraz@angouleme.fr"
      expect(current_email).not_to be_nil
      expect(current_email.subject).to match(/RDV .* modifié/)
      open_email "jungyoon@angouleme.fr"
      expect(current_email).not_to be_nil
      expect(current_email.subject).to match(/Nouveau RDV/)
    end

    context "un RDV existe à la même heure pour l’agent ajouté" do
      before { create(:rdv, agents: [agent_jungyoon], starts_at: rdv.starts_at) }

      it "affiche un avertissement, une fois contourné l’agent est bien ajouté" do
        visit edit_admin_organisation_rdv_path(organisation, rdv)
        select("Jung Yoon HAN", from: "rdv_agent_ids")
        click_button "Enregistrer"
        expect(page).to have_content "Ce rendez-vous en chevauche un autre"
        expect(rdv.reload.agents).to contain_exactly(agent_shiraz)
        click_button "Confirmer en ignorant les avertissements"
        expect(page).to have_content "Le rendez-vous a été modifié."
        expect(rdv.reload.agents).to contain_exactly(agent_shiraz, agent_jungyoon)
      end
    end
  end

  describe "mise en salle d’attente d’un usager" do
    context "l’option d’envoi de mail est désactivée" do
      it "n’affiche pas le bouton salle d’attente" do
        visit admin_organisation_rdv_path(organisation, rdv)
        expect(page).not_to have_link("Salle d’attente")
      end
    end

    context "l’option salle d’attente est activée par notification mail à l’agent" do
      let(:organisation) { create(:organisation, territory: create(:territory, enable_waiting_room_mail_field: true)) }

      before do
        visit admin_organisation_rdv_path(organisation, rdv)
      end

      it "ajoute l’usager en salle d’attente et retire le bouton" do
        click_link "Salle d’attente"

        within("#waiting_room_button-#{rdv.id}") do
          expect(page).to have_content("Usager en salle d'attente")
          expect(page).not_to have_content("Salle d'attente")
        end
        expect(rdv.reload.user_in_waiting_room?).to be true
      end

      it "envoie un email à l’agent" do
        expect do
          click_link "Salle d’attente"
          expect(page).to have_content("Usager en salle d'attente") # Permet d’attendre que la requête soit traitée
        end.to have_enqueued_mail(Agents::WaitingRoomMailer, :user_in_waiting_room).with(params: { agent: agent_shiraz, rdv: rdv }, args: [])
      end

      context "le RDV n’est pas pour aujourd’hui" do
        let(:starts_at) { 2.days.from_now }

        it "n’affiche pas le bouton salle d’attente" do
          visit admin_organisation_rdv_path(organisation, rdv)
          expect(page).not_to have_link("Salle d’attente")
        end
      end
    end

    context "l’option salle d’attente est activée par notification couleur à l’agent" do
      let(:organisation) { create(:organisation, territory: create(:territory, enable_waiting_room_color_field: true)) }

      before do
        visit admin_organisation_rdv_path(organisation, rdv)
      end

      it "ajoute l’usager en salle d’attente et retire le bouton" do
        click_link "Salle d’attente"

        within("#waiting_room_button-#{rdv.id}") do
          expect(page).to have_content("Usager en salle d'attente")
          expect(page).not_to have_content("Salle d'attente")
        end
        expect(rdv.reload.user_in_waiting_room?).to be true
      end

      it "n’envoie pas d’email à l’agent" do
        expect do
          click_link "Salle d’attente"
          expect(page).to have_content("Usager en salle d'attente") # Permet d’attendre que la requête soit traitée
        end.not_to have_enqueued_mail(Agents::WaitingRoomMailer, :user_in_waiting_room).with(params: { agent: agent_shiraz, rdv: rdv }, args: [])
      end

      context "le RDV n’est pas pour aujourd’hui" do
        let(:starts_at) { 2.days.from_now }

        it "n’affiche pas le bouton salle d’attente" do
          visit admin_organisation_rdv_path(organisation, rdv)
          expect(page).not_to have_link("Salle d’attente")
        end
      end
    end
  end

  describe "edition du contexte" do
    context "l’option de contexte est activée" do
      let(:territory) { create(:territory, enable_context_field: true) }

      it "permet de modifier le contexte du RDV" do
        visit edit_admin_organisation_rdv_path(organisation, rdv)
        fill_in "Contexte", with: "Besoin d'aide pour la déclaration d'impôts"
        click_button "Enregistrer"

        expect(page).to have_content("Le rendez-vous a été modifié.")
        expect(rdv.reload.context).to eq("Besoin d'aide pour la déclaration d'impôts")
      end
    end

    context "l’option de contexte n’est pas activée" do
      let(:territory) { create(:territory, enable_context_field: false) }

      it "n'affiche pas le champ de contexte" do
        visit edit_admin_organisation_rdv_path(organisation, rdv)
        expect(page).not_to have_field("Contexte")
      end
    end
  end
end
