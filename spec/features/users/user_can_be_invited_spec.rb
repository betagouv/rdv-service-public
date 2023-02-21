# frozen_string_literal: true

describe "User can be invited" do
  around { |example| perform_enqueued_jobs { example.run } }

  # needed for encrypted cookies
  before do
    stub_netsize_ok
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
  let!(:motif) { create(:motif, name: "RSA orientation sur site", bookable_publicly: true, organisation: organisation, service: agent.service) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:lieu2) { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: now - 1.month, motifs: [motif], lieu: lieu, organisation: organisation) }
  let!(:plage_ouverture2) { create(:plage_ouverture, :daily, first_day: now - 1.month, motifs: [motif], lieu: lieu2, organisation: organisation) }

  let!(:organisation2) { create(:organisation) }

  describe "in lieu selection page" do
    let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.where(id: [motif.id])) }

    before do
      travel_to(now)
      allow(Users::GeoSearch).to receive(:new).and_return(geo_search)
      allow_any_instance_of(ActionDispatch::Request).to receive(:cookie_jar).and_return(page.cookies)
      allow_any_instance_of(ActionDispatch::Request).to receive(:cookies).and_return(page.cookies)
    end

    it "shows the available lieux to take a rdv", js: true do
      visit prendre_rdv_path(
        departement: departement_number, city_code: city_code, invitation_token: invitation_token,
        address: "16 rue de la résistance", motif_search_terms: "RSA orientation"
      )

      # Lieu selection
      expect(page).to have_content(lieu.name)
      find(".card-title", text: /#{lieu.name}/).ancestor(".card").find("a.stretched-link").click

      # Creneau selection
      expect(page).to have_content(lieu.name)
      first(:link, "11:00").click

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

      # Clearing Cookies
      page.cookies.clear

      # Mail with
      open_email("johndoe@gmail.com")
      expect(current_email).to have_content(lieu.address)
      expect(current_email).to have_content(motif.name)
      expect(current_email).to have_content("11h00")
      current_email.click_link("Annuler ou modifier le rendez-vous")

      # Identity verification
      expect(page).to have_content("Entrez les 3 premières lettres de votre nom de famille")
      fill_in(:letter0, with: "A")
      fill_in(:letter1, with: "B")
      fill_in(:letter2, with: "C")

      expect(page).to have_content("Les 3 lettres ne correspondent pas au nom de famille.")
      fill_in(:letter0, with: "D")
      fill_in(:letter1, with: "O")
      fill_in(:letter2, with: "E")

      # RDV page
      expect(page).to have_content("Votre RDV")
      expect(page).to have_content(lieu.address)
      expect(page).to have_content("11h00")
    end

    context "when lieux do not have availability" do
      let!(:plage_ouverture) do
        create(:plage_ouverture, :daily, first_day: now + 8.days, motifs: [motif], lieu: lieu, organisation: organisation)
      end
      let!(:plage_ouverture2) do
        create(:plage_ouverture, :daily, first_day: now + 8.days, motifs: [motif], lieu: lieu2, organisation: organisation)
      end
      let!(:motif) do
        create(:motif, name: "RSA orientation sur site", max_public_booking_delay: 7.days, bookable_publicly: true, organisation: organisation, service: agent.service)
      end

      it "does not show the lieux" do
        visit prendre_rdv_path(
          departement: departement_number, city_code: city_code, invitation_token: invitation_token,
          address: "16 rue de la résistance", motif_search_terms: "RSA orientation"
        )

        expect(page).not_to have_content(lieu.name)
        expect(page).not_to have_content(lieu2.name)
        expect(page).to have_content("Nous n'avons pas trouvé de créneaux pour votre motif.")
      end
    end
  end

  describe "in motifs selection page" do
    let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.where(id: [motif.id, motif2.id])) }
    let!(:motif2) { create(:motif, name: "RSA orientation telephone", bookable_publicly: true, organisation: organisation2, service: agent.service) }
    let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif2], organisation: organisation2) }

    before do
      travel_to(now)
      allow(Users::GeoSearch).to receive(:new).and_return(geo_search)
    end

    it "shows the geo search available motifs to take a rdv", js: true do
      visit prendre_rdv_path(
        departement: departement_number, city_code: city_code, invitation_token: invitation_token,
        address: "16 rue de la résistance", motif_search_terms: "RSA orientation"
      )

      # Motif selection
      expect(page).to have_content(motif.name)
      expect(page).to have_content(motif2.name)
      find(".card-title", text: /#{motif.name}/).click

      # Restriction Page
      expect(page).to have_content("À lire avant de prendre un rendez-vous")
      expect(page).to have_content(motif.restriction_for_rdv)
      click_link("Accepter")

      # Lieu selection
      expect(page).to have_content(lieu.name)
      find(".card-title", text: /#{lieu.name}/).ancestor(".card").find("a.stretched-link").click

      # Creneau selection
      expect(page).to have_content(lieu.name)
      first(:link, "11:00").click

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

    context "when the organisations are preselected" do
      it "shows the available motifs for the preselected orgs" do
        visit prendre_rdv_path(
          departement: departement_number, city_code: city_code, invitation_token: invitation_token,
          address: "16 rue de la résistance", motif_search_terms: "RSA orientation", organisation_ids: [organisation.id]
        )

        # It directly selects the first motif and goes to lieu selection
        expect(page).to have_content(lieu.name)
        find(".card-title", text: /#{lieu.name}/).ancestor(".card").find("a.stretched-link").click
      end
    end
  end

  describe "when no motifs found through geo search" do
    let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.none) }
    let!(:motif2) { create(:motif, name: "RSA orientation telephone", bookable_publicly: true, organisation: organisation2, service: agent.service) }
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

    it "shows the organisations available motifs", js: true do
      # Motif selection
      expect(page).to have_content(motif.name)
      expect(page).to have_content(motif2.name)
    end
  end
end
