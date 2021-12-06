# frozen_string_literal: true

describe "User can be invited" do
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
  let!(:territory26) { create(:territory, departement_number: "26") }
  let!(:organisation) { create(:organisation, territory: territory26) }
  let!(:service) { create(:service) }
  let!(:motif) { create(:motif, service: service, name: "RDV RSA sur site", reservable_online: true, organisation: organisation) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: Date.new(2019, 7, 22), motifs: [motif], lieu: lieu, organisation: organisation) }

  describe "invitaton to lieu selection old path" do
    before do
      visit lieux_path(
        search: {
          departement: "26", where: "Drôme, Auvergne-Rhône-Alpes",
          service: service.id,
          motif_name_with_location_type: motif.name_with_location_type
        },
        invitation_token: invitation_token
      )
    end

    it "default", js: true do
      # Step 4
      expect(page).to have_content(lieu.name)

      # Step 5
      find(".card-title", text: /#{lieu.name}/).ancestor(".card").find("a.stretched-link").click
      expect(page).to have_content(lieu.name)
      first(:link, "11:00").click

      # Restriction Page
      expect(page).to have_content("À lire avant de prendre un rendez-vous")
      expect(page).to have_content(motif.restriction_for_rdv)
      click_link("Accepter")

      # Invitation page
      expect(page).to have_content("Inscription")
      expect(page).to have_field("Prénom", with: user.first_name)
      expect(page).to have_field("Nom d’usage", with: user.last_name)
      expect(page).to have_field("Email", disabled: true, with: user.email)
      expect(page).to have_field("Téléphone", with: user.phone_number)

      fill_in(:password, with: "12345678")
      click_button("Enregistrer")

      # Redirects to rdv informations
      expect(page).to have_content("Votre mot de passe a correctement été enregistré. Vous êtes maintenant connecté.")
      expect(page).to have_content("Vos informations")
      expect(page).to have_field("Date de naissance", with: "20/12/1988")
      expect(page).to have_field("Adresse", with: user.address)
      click_button("Continuer")

      # Choix de l'usager
      expect(page).to have_content("Choix de l'usager")
      expect(page).to have_content(user.full_name)
      click_button("Continuer")

      # Confirmation
      expect(page).to have_content("Informations de contact")
      expect(page).to have_content("johndoe@gmail.com")
      expect(page).to have_content("0682605955")
      click_link("Confirmer mon RDV")

      # RDV page
      expect(page).to have_content("Vos rendez-vous")
      expect(page).to have_content(motif.name)
      expect(page).to have_content(lieu.address)
      expect(page).to have_content("11h00")
    end
  end

  describe "invitation to lieu selection new path" do
    before do
      visit prendre_rdv_path(
        departement: "26", address: "Drôme, Auvergne-Rhône-Alpes",
        organisation_id: organisation.id,
        service_id: motif.service_id,
        motif_id: motif.id,
        invitation_token: invitation_token
      )
    end

    it "default", js: true do
      # Step 4
      expect(page).to have_content(lieu.name)
      find(".card-title", text: /#{lieu.name}/).ancestor(".card").find("a.stretched-link").click

      # Step 5
      expect(page).to have_content(lieu.name)
      first(:link, "11:00").click

      # Restriction Page
      expect(page).to have_content("À lire avant de prendre un rendez-vous")
      expect(page).to have_content(motif.restriction_for_rdv)
      click_link("Accepter")

      # Invitation page
      expect(page).to have_content("Inscription")
      expect(page).to have_field("Prénom", with: user.first_name)
      expect(page).to have_field("Nom d’usage", with: user.last_name)
      expect(page).to have_field("Email", disabled: true, with: user.email)
      expect(page).to have_field("Téléphone", with: user.phone_number)

      fill_in(:password, with: "12345678")
      click_button("Enregistrer")

      # Redirects to rdv informations
      expect(page).to have_content("Votre mot de passe a correctement été enregistré. Vous êtes maintenant connecté.")
      expect(page).to have_content("Vos informations")
      expect(page).to have_field("Date de naissance", with: "20/12/1988")
      expect(page).to have_field("Adresse", with: user.address)
      click_button("Continuer")

      # Choix de l'usager
      expect(page).to have_content("Choix de l'usager")
      expect(page).to have_content(user.full_name)
      click_button("Continuer")

      # Confirmation
      expect(page).to have_content("Informations de contact")
      expect(page).to have_content("johndoe@gmail.com")
      expect(page).to have_content("0682605955")
      click_link("Confirmer mon RDV")

      # RDV page
      expect(page).to have_content("Vos rendez-vous")
      expect(page).to have_content(motif.name)
      expect(page).to have_content(lieu.address)
      expect(page).to have_content("11h00")
    end
  end

  describe "invitation to motifs selection" do
    before do
      visit prendre_rdv_path(
        departement: "26", address: "Drôme, Auvergne-Rhône-Alpes",
        organisation_id: organisation.id,
        service_id: motif.service_id,
        invitation_token: invitation_token
      )
    end

    it "default", js: true do
      # Step 3
      expect(page).to have_content(motif.name)
      find(".card-title", text: /#{motif.name}/).click

      # Step 4
      expect(page).to have_content(lieu.name)
      find(".card-title", text: /#{lieu.name}/).ancestor(".card").find("a.stretched-link").click

      # Step 5
      expect(page).to have_content(lieu.name)
      first(:link, "11:00").click

      # Restriction Page
      expect(page).to have_content("À lire avant de prendre un rendez-vous")
      expect(page).to have_content(motif.restriction_for_rdv)
      click_link("Accepter")

      # Invitation page
      expect(page).to have_content("Inscription")
      expect(page).to have_field("Prénom", with: user.first_name)
      expect(page).to have_field("Nom d’usage", with: user.last_name)
      expect(page).to have_field("Email", disabled: true, with: user.email)
      expect(page).to have_field("Téléphone", with: user.phone_number)

      fill_in(:password, with: "12345678")
      click_button("Enregistrer")

      # Redirects to rdv informations
      expect(page).to have_content("Votre mot de passe a correctement été enregistré. Vous êtes maintenant connecté.")
      expect(page).to have_content("Vos informations")
      expect(page).to have_field("Date de naissance", with: "20/12/1988")
      expect(page).to have_field("Adresse", with: user.address)
      click_button("Continuer")

      # Choix de l'usager
      expect(page).to have_content("Choix de l'usager")
      expect(page).to have_content(user.full_name)
      click_button("Continuer")

      # Confirmation
      expect(page).to have_content("Informations de contact")
      expect(page).to have_content("johndoe@gmail.com")
      expect(page).to have_content("0682605955")
      click_link("Confirmer mon RDV")

      # RDV page
      expect(page).to have_content("Vos rendez-vous")
      expect(page).to have_content(motif.name)
      expect(page).to have_content(lieu.address)
      expect(page).to have_content("11h00")
    end
  end
end
