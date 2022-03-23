# frozen_string_literal: true

describe "User can be invited" do
  # needed for encrypted cookies
  before do
    allow_any_instance_of(ActionDispatch::Request).to receive(:cookie_jar).and_return(page.cookies)
    allow_any_instance_of(ActionDispatch::Request).to receive(:cookies).and_return(page.cookies)
  end

  let(:now) { Time.zone.parse("2021-12-13 10:30") }
  let!(:user) do
    create(:user, first_name: "john", last_name: "doe", email: "johndoe@gmail.com",
                  phone_number: "0682605955", address: "26 avenue de la resistance",
                  birth_date: Date.new(1988, 12, 20),
                  organisations: [organisation])
  end
  let!(:invitation_token) do
    user.invite! { |u| u.skip_invitation = true }
    user.raw_invitation_token
  end
  let!(:agent) { create(:agent) }
  let!(:departement_number) { "26" }
  let!(:city_code) { "26000" }
  let!(:territory26) { create(:territory, departement_number: departement_number) }
  let!(:organisation) { create(:organisation, territory: territory26) }
  let!(:motif) { create(:motif, name: "RSA orientation sur site", reservable_online: true, organisation: organisation) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: now - 1.month, motifs: [motif], lieu: lieu, organisation: organisation) }

  let!(:organisation2) { create(:organisation) }

  describe "invitation to lieu selection new path" do
    let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.where(id: [motif.id])) }

    before do
      travel_to(now)
      allow(Users::GeoSearch).to receive(:new).and_return(geo_search)

      visit prendre_rdv_path(
        departement: departement_number, city_code: city_code, invitation_token: invitation_token,
        address: "16 rue de la résistance", motif_search_terms: "RSA orientation"
      )
    end

    it "default", js: true do
      # Lieu selection
      expect(page).to have_content(lieu.name)
      find(".card-title", text: /#{lieu.name}/).ancestor(".card").find("a.stretched-link").click

      # Creneau selection
      expect(page).to have_content(lieu.name)
      first(:link, "11:00").click

      # Restriction Page
      expect(page).to have_content("À lire avant de prendre un rendez-vous")
      expect(page).to have_content(motif.restriction_for_rdv)
      click_link("Accepter")

      # RDV informations
      expect(page).to have_content("Vos informations")
      expect(page).not_to have_field("Date de naissance")
      expect(page).not_to have_field("Adresse")
      expect(page).to have_field("Email", with: user.email, disabled: true)
      expect(page).to have_field("Téléphone", with: user.phone_number)
      click_button("Continuer")

      # Confirmation
      expect(page).to have_content("Informations de contact")
      expect(page).to have_content("johndoe@gmail.com")
      expect(page).to have_content("0682605955")
      click_link("Confirmer mon RDV")

      # RDV page
      expect(page).to have_content("Votre RDV")
      expect(page).to have_content(lieu.address)
      expect(page).to have_content("11h00")
    end
  end

  describe "invitation to motifs selection" do
    let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.where(id: [motif.id, motif2.id])) }
    let!(:motif2) { create(:motif, name: "RSA orientation telephone", reservable_online: true, organisation: organisation2) }
    let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif2], organisation: organisation2) }

    before do
      travel_to(now)
      allow(Users::GeoSearch).to receive(:new).and_return(geo_search)

      visit prendre_rdv_path(
        departement: departement_number, city_code: city_code, invitation_token: invitation_token,
        address: "16 rue de la résistance", motif_search_terms: "RSA orientation"
      )
    end

    it "default", js: true do
      # Motif selection
      expect(page).to have_content(motif.name)
      expect(page).to have_content(motif2.name)
      find(".card-title", text: /#{motif.name}/).click

      # Lieu selection
      expect(page).to have_content(lieu.name)
      find(".card-title", text: /#{lieu.name}/).ancestor(".card").find("a.stretched-link").click

      # Creneau selection
      expect(page).to have_content(lieu.name)
      first(:link, "11:00").click

      # Restriction Page
      expect(page).to have_content("À lire avant de prendre un rendez-vous")
      expect(page).to have_content(motif.restriction_for_rdv)
      click_link("Accepter")

      # RDV informations
      expect(page).to have_content("Vos informations")
      expect(page).not_to have_field("Date de naissance")
      expect(page).not_to have_field("Adresse")
      expect(page).to have_field("Email", with: user.email, disabled: true)
      expect(page).to have_field("Téléphone", with: user.phone_number)
      click_button("Continuer")

      # Confirmation
      expect(page).to have_content("Informations de contact")
      expect(page).to have_content("johndoe@gmail.com")
      expect(page).to have_content("0682605955")
      click_link("Confirmer mon RDV")

      # RDV page
      expect(page).to have_content("Votre RDV")
      expect(page).to have_content(lieu.address)
      expect(page).to have_content("11h00")
    end
  end

  describe "when no motifs found through geo search" do
    let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.none) }
    let!(:motif2) { create(:motif, name: "RSA orientation telephone", reservable_online: true, organisation: organisation2) }
    let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif2], organisation: organisation2) }

    before do
      travel_to(now)
      allow(Users::GeoSearch).to receive(:new).and_return(geo_search)

      visit prendre_rdv_path(
        departement: departement_number, city_code: city_code, invitation_token: invitation_token,
        address: "16 rue de la résistance", motif_search_terms: "RSA orientation",
        organisation_ids: [organisation.id, organisation2.id]
      )
    end

    it "default", js: true do
      # Motif selection
      expect(page).to have_content(motif.name)
      expect(page).to have_content(motif2.name)
      find(".card-title", text: /#{motif.name}/).click

      # Lieu selection
      expect(page).to have_content(lieu.name)
      find(".card-title", text: /#{lieu.name}/).ancestor(".card").find("a.stretched-link").click

      # Crenenau selection
      expect(page).to have_content(lieu.name)
      first(:link, "11:00").click

      # Restriction Page
      expect(page).to have_content("À lire avant de prendre un rendez-vous")
      expect(page).to have_content(motif.restriction_for_rdv)
      click_link("Accepter")

      # RDV informations
      expect(page).to have_content("Vos informations")
      expect(page).not_to have_field("Date de naissance")
      expect(page).not_to have_field("Adresse")
      expect(page).to have_field("Email", with: user.email, disabled: true)
      expect(page).to have_field("Téléphone", with: user.phone_number)
      click_button("Continuer")

      # Confirmation
      expect(page).to have_content("Informations de contact")
      expect(page).to have_content("johndoe@gmail.com")
      expect(page).to have_content("0682605955")
      click_link("Confirmer mon RDV")

      # RDV page
      expect(page).to have_content("Votre RDV")
      expect(page).to have_content(lieu.address)
      expect(page).to have_content("11h00")
    end
  end
end
