RSpec.describe "Agent can list RDVs" do
  let!(:organisation) { organisations(:default_org) }
  let!(:current_agent) { create(:agent, organisations: [organisation], service: create(:service)) }
  let!(:user) { create(:user) }

  def user_profile_path(user)
    admin_organisation_user_path(organisation_id: organisation.id, id: user.id)
  end

  before do
    login_as(current_agent, scope: :agent)
  end

  it "displays user info for each RDV" do
    organisation.territory.update!(enable_notes_field: true)
    motif = create(:motif, service: current_agent.services.first, organisation:)
    create(:rdv, organisation: organisation, agents: [current_agent], users: [user], motif: motif)
    user.annotate!("Ma remarque", territory: organisation.territory)

    visit admin_organisation_rdvs_url(organisation)
    expect(page).to have_content(user.full_name)
    expect(page).to have_content(motif.name)
    expect(page.html).to include("Ma remarque")
  end

  describe "RDV visibility within organisation" do
    let!(:agent_from_same_service) { create(:agent, organisations: [organisation], service: current_agent.services.first) }
    let!(:agent_from_other_service) { create(:agent, organisations: [organisation], service: create(:service)) }

    before do
      [current_agent, agent_from_same_service, agent_from_other_service].each do |agent|
        create(:rdv, organisation: organisation, agents: [agent], motif: create(:motif, service: agent.services.first, organisation:))
      end
    end

    it "displays RDVs whose motif are in the same service as current agent" do
      visit admin_organisation_rdvs_url(organisation)
      expect(page).to have_content(current_agent.rdvs.last.motif.name)
      expect(page).to have_content(agent_from_same_service.rdvs.last.motif.name)
      expect(page).not_to have_content(agent_from_other_service.rdvs.last.motif.name)
    end
  end

  context "when a RDV user is soft deleted" do
    let(:active_user) { user }
    let!(:deleted_user) { create(:user) }

    before do
      create(:rdv, organisation: organisation, agents: [current_agent], users: [active_user])
      create(:rdv, :past, organisation: organisation, agents: [current_agent], users: [deleted_user])

      deleted_user.soft_delete!
    end

    it "displays deleted users without a link to their profile" do
      visit admin_organisation_rdvs_url(organisation)

      # Active user has a link to her profile
      expect(page).to have_link(active_user.full_name, href: user_profile_path(active_user))

      # Deleted user has a link to her profile
      expect(page).to have_content("#{deleted_user}Supprimé")
      expect(page.body).not_to include(user_profile_path(deleted_user))
    end
  end

  context "when a RDV is by_phone with no lieu" do
    before do
      create(:rdv, :by_phone, lieu: nil, organisation: organisation, agents: [current_agent], users: [user])
    end

    it "displays RDVs list with no error" do
      visit admin_organisation_rdvs_url(organisation)

      expect(page).to have_content("RDV téléphonique")
      expect(page).to have_content(current_agent.first_name)
      expect(page).to have_link(user.full_name, href: user_profile_path(user))
    end
  end

  describe "searching by user" do
    let(:motif) { create(:motif, name: "Suivi de dossier", organisation: organisation) }

    before do
      create(:rdv, organisation: organisation, users: [user], agents: [current_agent], motif: motif)
    end

    it "allows searching by user", js: true do
      visit admin_organisation_rdvs_path(organisation)

      find("#select2-user_id-container").click
      within(".select2-search--dropdown") do
        fill_in(class: "select2-search__field", with: "#{user.last_name} #{user.first_name}")
      end
      expect(page).to have_content(user.reverse_full_name)
      find("li", text: "#{user.last_name} #{user.first_name}").click

      # This is to make sure we wait for the user to be added before doing the next action
      expect(page).to have_content(user.reverse_full_name)
      click_on("Rafraîchir la liste")
      expect(page).to have_content(motif.name) # Permet de vérifier que le rdv est bien affiché
    end
  end

  describe "cohérence du compteur pour les RDV avec plusieurs agents" do
    context "un seul RDV avec deux agents" do
      let!(:current_agent) { create(:agent, admin_role_in_organisations: [organisation]) }
      let!(:other_agent) { create(:agent, organisations: [organisation]) }
      let!(:rdv) { create(:rdv, organisation: organisation, agents: [current_agent, other_agent]) }

      it "devrait afficher des compteurs de RDV égaux à 1" do
        visit admin_organisation_rdvs_path(organisation)
        expect(page).to have_content("Exporter le RDV en XLS")
        expect(find("h4", text: /1 rendez-vous/)).to be_present
      end
    end

    context "panaché de RDV" do
      let!(:current_agent) { create(:agent, admin_role_in_organisations: [organisation]) }
      let!(:other_agent) { create(:agent, organisations: [organisation]) }
      let!(:other_agent2) { create(:agent, organisations: [organisation]) }

      before do
        create(:rdv, organisation: organisation, agents: [current_agent, other_agent])
        create(:rdv, organisation: organisation, agents: [current_agent])
        create(:rdv, organisation: organisation, agents: [other_agent])
        create(:rdv, organisation: organisation, agents: [current_agent, other_agent, other_agent2])
      end

      it "devrait afficher le bon nombre de RDV" do
        visit admin_organisation_rdvs_path(organisation)
        expect(page).to have_content("Exporter les 4 RDV en XLS")
        expect(find("h4", text: /4 rendez-vous/)).to be_present
      end
    end
  end

  describe "via la route qui n'utilise pas d'id d'organisation" do
    context "quand l'agent a accès au rdv" do
      let(:rdv) { create(:rdv, agents: [current_agent], organisation: organisation) }

      it "redirige vers la page de détails du rdv dans le contexte de son organisation" do
        visit agents_rdv_path(rdv.id)
        expect(page).to have_current_path(admin_organisation_rdv_path(rdv.organisation_id, rdv))
      end
    end

    context "quand l'agent n'a pas accès au rendez-vous" do
      let(:rdv) { create(:rdv, agents: [current_agent]) }

      it "affiche une erreur" do
        expect { visit agents_rdv_path(rdv.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "configuration du nombre de RDV par page", js: true do
    before { create_list(:rdv, 54, organisation:, agents: [current_agent]) }

    it "fonctionne de manière cohérente" do
      # par défaut la liste affiche 10 RDV par page
      visit admin_organisation_rdvs_path(organisation)
      expect(page).to have_selector(".rdv-item", count: 10)
      expect(Rack::Utils.parse_query(URI.parse(first(".fr-pagination__link--last")["href"]).query)["page"].to_i).to eq(6)
      expect(first(".rdv-per-page-list").find(".fr-pagination__link--current").text.to_i).to eq 10
      # on passe à 25 par page
      first(".rdv-per-page-list").find(".fr-pagination__link", text: /25/).click
      expect(page).to have_selector(".rdv-item", count: 25)
      expect(Rack::Utils.parse_query(URI.parse(first(".fr-pagination__link--last")["href"]).query)["page"].to_i).to eq(3)
      expect(first(".rdv-per-page-list").find(".fr-pagination__link--current").text.to_i).to eq 25
      # on passe à 50 par page
      first(".rdv-per-page-list").find(".fr-pagination__link", text: /50/).click
      expect(page).to have_selector(".rdv-item", count: 50)
      expect(Rack::Utils.parse_query(URI.parse(first(".fr-pagination__link--last")["href"]).query)["page"].to_i).to eq(2)
      expect(first(".rdv-per-page-list").find(".fr-pagination__link--current").text.to_i).to eq 50
      # on va à la deuxième page et on vérifie que 50 RDV par page est toujours sélectionné
      first('.fr-pagination__link[title="Page 2"]').click
      expect(first(".rdv-per-page-list").find(".fr-pagination__link--current").text.to_i).to eq 50
      expect(page).to have_selector(".rdv-item", count: 4)
      # on change un filtre et on vérifie que le nombre de RDV par page est retenu
      select("Rendez-vous à venir", from: "status")
      click_on "Rafraîchir la liste"
      expect(first(".rdv-per-page-list").find(".fr-pagination__link--current").text.to_i).to eq 50
      # en revanche ça fait revenir à la première page, ce qui est raisonnable
      expect(first(".fr-pagination__link.fr-pagination__link--current")["title"]).to eq "Page 1"
      expect(page).to have_selector(".rdv-item", count: 50)
      # on revient à 10 par page
      first(".rdv-per-page-list").find(".fr-pagination__link", text: /10/).click
      expect(page).to have_selector(".rdv-item", count: 10)
      expect(first(".rdv-per-page-list").find(".fr-pagination__link--current").text.to_i).to eq 10
      # le filtre sur le statut est bien conservé
      expect(page).to have_select("status", selected: "Rendez-vous à venir")
    end
  end
end
