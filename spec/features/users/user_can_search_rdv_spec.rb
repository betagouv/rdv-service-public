# frozen_string_literal: true

describe "User can search for rdvs" do
  let(:now) { Time.zone.parse("2021-12-13 8:00") }

  let!(:territory92) { create(:territory, departement_number: "92") }
  let!(:organisation) { create(:organisation, :with_contact, territory: territory92) }
  let(:service) { create(:service) }
  let!(:motif) { create(:motif, name: "Vaccination", reservable_online: true, organisation: organisation, restriction_for_rdv: nil, service: service) }
  let!(:autre_motif) { create(:motif, name: "Consultation", reservable_online: true, organisation: organisation, restriction_for_rdv: nil, service: service) }
  let!(:motif_autre_service) { create(:motif, :by_phone, name: "Télé consultation", reservable_online: true, organisation: organisation, restriction_for_rdv: nil, service: create(:service)) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: now + 1.month, motifs: [motif], lieu: lieu, organisation: organisation) }
  let!(:autre_plage_ouverture) { create(:plage_ouverture, :daily, first_day: now + 1.month, motifs: [autre_motif], lieu: lieu, organisation: organisation) }
  let!(:plage_ouverture_autre_service) { create(:plage_ouverture, :daily, first_day: now + 1.month, motifs: [motif_autre_service], lieu: lieu, organisation: organisation) }
  let!(:lieu2) { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture2) { create(:plage_ouverture, :daily, first_day: now + 1.month, motifs: [motif], lieu: lieu2, organisation: organisation) }

  around { |example| perform_enqueued_jobs { example.run } }

  before do
    travel_to(now)
    stub_netsize_ok
  end

  describe "default" do
    it "default", js: true do
      visit root_path
      execute_search
      choose_service(motif.service)
      choose_motif(motif)
      choose_lieu(lieu)
      choose_creneau
      sign_up
      continue_to_rdv(motif)
      add_relative
      confirm_rdv(motif, lieu)
    end

    context "when the motif doesn't require a lieu" do
      before { create(:plage_ouverture, lieu: nil, motifs: [motif_autre_service], organisation: organisation, first_day: 1.day.since) }

      shared_examples "take a rdv without lieu" do
        it "can take a RDV when there are creneaux without lieu", js: true do
          visit root_path
          execute_search
          choose_service(motif_autre_service.service)
          choose_organisation(organisation)
          choose_creneau
          sign_up
          continue_to_rdv(motif_autre_service)
          add_relative
          confirm_rdv(motif_autre_service)
        end
      end

      context "when the motif is by phone" do
        let!(:motif_autre_service) { create(:motif, :by_phone, name: "Télé consultation", reservable_online: true, organisation: organisation, restriction_for_rdv: nil, service: create(:service)) }

        it_behaves_like "take a rdv without lieu"
      end

      context "when the motif is at home" do
        let!(:motif_autre_service) { create(:motif, :at_home, name: "À domicile", reservable_online: true, organisation: organisation, restriction_for_rdv: nil, service: create(:service)) }

        it_behaves_like "take a rdv without lieu"
      end
    end
  end

  describe "follow up rdvs" do
    let!(:user) { create(:user, agents: [agent]) }
    let!(:agent) { create(:agent) }
    let!(:agent2) { create(:agent) }

    ## follow up motif linked to referent
    let!(:motif1) do
      create(
        :motif,
        name: "RSA Suivi", follow_up: true, reservable_online: true,
        organisation: organisation, service: service
      )
    end

    ## follow up motif not linked to referent
    let!(:motif2) do
      create(
        :motif,
        name: "RSA suivi téléphonique", follow_up: true, reservable_online: true, organisation: organisation,
        restriction_for_rdv: nil, service: service
      )
    end

    ## non follow up motif linked to referent
    let!(:motif3) do
      create(
        :motif,
        name: "RSA Orientation", follow_up: false, reservable_online: true, organisation: organisation,
        restriction_for_rdv: nil, service: service
      )
    end

    ## POs
    let!(:plage_ouverture) do
      create(
        :plage_ouverture, :daily,
        agent: agent, motifs: [motif1], organisation: organisation, first_day: Time.zone.parse("2021-12-15"), lieu: lieu,
        start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(12)
      )
    end
    let!(:plage_ouverture2) do
      create(
        :plage_ouverture,
        agent: agent2, motifs: [motif2], organisation: organisation, first_day: Time.zone.parse("2021-12-15"), lieu: lieu,
        start_time: Tod::TimeOfDay.new(16), end_time: Tod::TimeOfDay.new(17)
      )
    end
    let!(:plage_ouverture3) do
      create(
        :plage_ouverture, :daily,
        agent: agent, motifs: [motif3], organisation: organisation, first_day: Time.zone.parse("2021-12-15"), lieu: lieu,
        start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(17)
      )
    end
    # Available PO for selected motif on other agent
    let!(:plage_ouverture4) do
      create(
        :plage_ouverture, :daily,
        agent: agent2, motifs: [motif1], organisation: organisation, first_day: Time.zone.parse("2021-12-15"), lieu: lieu,
        start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(15)
      )
    end

    ## Collectif follow up motif linked to referent
    let!(:collectif_motif) do
      create(:motif, follow_up: true, restriction_for_rdv: nil, collectif: true, organisation: organisation, reservable_online: true, service: service)
    end
    let!(:collectif_rdv) { create(:rdv, motif: collectif_motif, agents: [agent], starts_at: 2.days.from_now) }

    before { login_as(user, scope: :user) }

    it "shows only the follow up motifs related to the agent" do
      visit root_path(referent_ids: [agent.id], departement: "92", service_id: service.id)

      ### Motif selection
      expect(page).to have_content(motif1.name)
      expect(page).to have_content(collectif_motif.name)

      expect(page).not_to have_content(motif2.name)
      expect(page).not_to have_content(motif3.name)

      find(".card-title", text: /#{motif1.name}/).click
      click_link("Accepter")

      expect(page).to have_content(lieu.name)
      find(".card-title", text: /#{lieu.name}/).ancestor(".card").find("a.stretched-link").click

      ### Creneau selection
      expect(page).to have_content(agent.last_name.upcase)
      expect(page).to have_content("09:00")
      expect(page).not_to have_content("14:00")

      first(:link, "09:00").click

      ## Take rdv
      expect(page).to have_content("Vos informations")
      click_button("Continuer")
      expect(page).to have_content("Choix de l'usager")
      click_button("Continuer")
      expect(page).to have_content("Confirmation")
      click_link("Confirmer mon RDV")

      expect(page).to have_content("Votre RDV")
      expect(page).to have_content(lieu.address)
      expect(page).to have_content(motif1.name)
      expect(page).to have_content("09h00")
    end

    context "when the agent is not the referent" do
      it "shows an error message" do
        visit root_path(referent_ids: [agent2.id], departement: "92", service_id: service.id)

        expect(page).not_to have_content(motif1.name)
        expect(page).not_to have_content(collectif_motif.name)
        expect(page).not_to have_content(motif2.name)
        expect(page).not_to have_content(motif3.name)

        expect(page).to have_content("L'agent avec qui vous voulez prendre rendez-vous ne vous est pas assigné comme référent")
      end
    end

    context "when the agent has no PO" do
      let!(:user) { create(:user, agents: [agent3]) }
      let!(:agent3) { create(:agent) }

      it "shows an error message" do
        visit root_path(referent_ids: [agent3.id], departement: "92", service_id: service.id)

        expect(page).to have_content("Votre référent n'a pas de créneaux disponibles")
      end
    end
  end

  private

  def execute_search
    expect_page_h1("Prenez rendez-vous en ligne\navec votre département")
    fill_in("search_where", with: "79 Rue de Plaisance, 92250 La Garenne-Colombes")

    # fake algolia autocomplete to pass on Circle ci
    page.execute_script("document.querySelector('#search_departement').value = '92'")
    page.execute_script("document.querySelector('#search_submit').disabled = false")

    click_button("Rechercher")
  end

  def choose_service(service)
    expect_page_h1("Prenez rendez-vous en ligne\navec votre département le 92")
    expect(page).to have_content("Vous souhaitez prendre un RDV avec le service :")

    find("h3", text: service.name).click
  end

  def choose_motif(motif)
    expect(page).to have_content("Sélectionnez le motif de votre RDV")
    find("h3", text: motif.name).click
  end

  def choose_lieu(lieu)
    expect(page).to have_content(lieu.name)
    expect(page).to have_content(lieu2.name)

    find(".card-title", text: /#{lieu.name}/).ancestor(".card").find("a.stretched-link").click

    expect(page).to have_content(lieu.name)
  end

  def choose_organisation(organisation)
    expect(page).to have_content(organisation.name)
    expect(page).to have_content(organisation.phone_number)
    expect(page).to have_content(organisation.website)

    find("h3", text: organisation.name).click
  end

  def choose_creneau
    first(:link, "11:00").click
  end

  def sign_up
    # Login page
    click_link("Je m'inscris")

    # Sign up page
    expect(page).to have_content("Inscription")
    fill_in(:user_first_name, with: "Michel")
    fill_in(:user_last_name, with: "Lapin")
    fill_in("Email", with: "michel@lapin.fr")
    fill_in("Téléphone", with: "0612345678")
    click_button("Je m'inscris")

    # Confirmation email
    open_email("michel@lapin.fr")
    expect(current_email).to have_content("Merci pour votre inscription")
    current_email.click_link("Confirmer mon compte")

    # Password reset page after confirmation
    expect(page).to have_content("Votre compte a été validé")
    expect(page).to have_content("Définir mon mot de passe")
    fill_in(:password, with: "12345678")
    click_button("Enregistrer")
  end

  def continue_to_rdv(motif)
    expect(page).to have_content("Vos informations")
    fill_in("Date de naissance", with: Time.zone.yesterday.strftime("%d/%m/%Y"))
    fill_in("Nom de naissance", with: "Lapinou")
    click_button("Continuer")

    expect(page).to have_content(motif.name)
    expect(page).to have_content("Michel LAPIN (Lapinou)")
  end

  def add_relative
    click_link("Ajouter un proche")
    expect(page).to have_selector("h1", text: "Ajouter un proche")
    fill_in("Prénom", with: "Mathieu")
    fill_in("Nom", with: "Lapin")
    fill_in("Date de naissance", with: Date.yesterday)
    click_button("Enregistrer")
    expect(page).to have_content("Mathieu LAPIN")

    click_button("Continuer")
  end

  def confirm_rdv(motif, lieu = nil)
    expect(page).to have_content("Informations de contact")
    expect(page).to have_content("Mathieu LAPIN")
    click_link("Confirmer mon RDV")

    expect(page).to have_content("Votre RDV")
    expect(page).to have_content(lieu.address) if lieu.present?
    expect(page).to have_content(motif.name)
    expect(page).to have_content("11h00")
  end

  def expect_page_h1(title)
    expect(page).to have_selector("h1", text: title)
  end
end
