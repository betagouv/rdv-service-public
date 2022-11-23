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
