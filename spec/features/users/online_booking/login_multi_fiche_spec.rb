RSpec.describe "Login multi-fiches durant la prise de RDV en ligne" do
  let(:now) { Time.zone.parse("2021-12-13 8:00") }
  let!(:territory)      { create(:territory, departement_number: "92") }
  let!(:organisation)   { create(:organisation, territory: territory) }
  let!(:service)        { create(:service) }
  let!(:motif)          { create(:motif, name: "Consultation", organisation: organisation, restriction_for_rdv: nil, service: service) }
  let!(:lieu)           { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture) do
    create(:plage_ouverture, :weekdays, first_day: now + 1.month, motifs: [motif], lieu: lieu, organisation: organisation)
  end

  before do
    travel_to(now)
    stub_netsize_ok
  end

  def reach_creneau_page
    visit prendre_rdv_path(
      departement: territory.departement_number,
      lieu_id: lieu.id,
      motif_name_with_location_type: "#{motif.name.parameterize}-public_office",
      service_id: service.id,
      date: (now + 1.month).to_s
    )
    first(:link, "11:00").click
  end

  def enter_code_for(email, first_name:, last_name:)
    fill_in("Prénom", with: first_name)
    fill_in("Nom", with: last_name)
    fill_in("Adresse email", with: email)
    click_button("Recevoir un code de connexion")
    fill_in("Code à 6 chiffres", with: LoginCode.most_recent_usable_for(email: email).code)
    click_on("Valider")
  end

  context "quand deux fiches usager partagent le même email dans le même territoire" do
    let!(:organisation_2) { create(:organisation, territory: territory) }
    let!(:user_1) { create(:user, email: "multi@test.fr", first_name: "Alice", last_name: "Dupont", organisations: [organisation]) }
    let!(:user_2) { create(:user, email: "multi@test.fr", first_name: "Bob", last_name: "Martin", organisations: [organisation_2]) }

    it "interrompt le wizard pour afficher l'écran de sélection de fiche, puis reprend le wizard après le choix" do
      reach_creneau_page
      enter_code_for("multi@test.fr", first_name: "Alice", last_name: "Dupont")

      expect(page).to have_content(%(Plusieurs fiches usagers sont liées à l'adresse "multi@test.fr".))
      expect(page).to have_content(user_1.full_name)
      expect(page).to have_content(user_2.full_name)

      click_on user_1.full_name

      expect(page).to have_content("Connexion réussie")
      expect(page).to have_content("Étape 1 sur 3")
    end
  end

  context "quand une fiche existe dans le territoire mais avec un prénom/nom différent de ceux saisis dans le formulaire de connexion" do
    let!(:user) { create(:user, email: "alice@test.fr", first_name: "Alice", last_name: "Dupont", organisations: [organisation]) }

    it "connecte l'usager sur sa fiche existante sans modifier ses noms" do
      reach_creneau_page
      enter_code_for("alice@test.fr", first_name: "Bob", last_name: "Martin")

      expect(page).to have_content("Connexion réussie")
      expect(page).to have_content("Étape 1 sur 3")
      expect(user.reload.first_name).to eq("Alice")
      expect(user.reload.last_name).to eq("Dupont")
    end
  end
end
