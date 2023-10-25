# frozen_string_literal: true

describe "User can search rdv on rdv service public" do
  include_context "rdv_mairie_api_authentication"

  let(:now) { Time.zone.parse("2021-12-13 8:00") }
  let!(:territory) { create(:territory, departement_number: "MA") }
  let!(:organisation) { create(:organisation, :with_contact, territory: territory, verticale: :rdv_mairie) }
  let(:service) { create(:service) }
  let!(:demarches_simplifies_motif) do
    create(:motif, name: "Clarification du dossier", organisation: organisation, restriction_for_rdv: nil, service: service, default_duration_in_min: 25)
  end

  let!(:lieu) { create(:lieu, organisation: organisation, name: "Mairie de Sannois", address: "15 Place du Général Leclerc, Sannois, 95110") }
  let(:user) { create(:user, email: "jeanmairie@example.com") }

  def json_response
    JSON.parse(page.html)
  end

  before do
    default_url_options[:host] = "http://www.rdv-mairie-test.localhost"
    travel_to(now)
    create(:plage_ouverture, :no_recurrence, first_day: now, motifs: [demarches_simplifies_motif], lieu: lieu, organisation: organisation, start_time: Tod::TimeOfDay(9),
                                             end_time: Tod::TimeOfDay.new(10))
  end

  it "allows booking a rdv", js: true do
    visit public_link_to_org_url(organisation_id: organisation.id, host: "http://www.rdv-mairie-test.localhost")
    click_on("Clarification du dossier")
    click_on("Prochaine disponibilité le") # choix du lieu

    first(:link, "09:00").click
    expect(page).to have_current_path("/users/sign_in")
    expect(page).to have_content("Vous devez vous connecter ou vous inscrire pour continuer")

    fill_in("user_email", with: user.email)
    fill_in("password", with: user.password)
    click_button("Se connecter")

    expect(page).not_to have_field("Numéro de pré-demande ANTS")

    click_button("Continuer")
    click_button("Continuer")
    click_link("Confirmer mon RDV")
    expect(page).to have_content("Votre rendez vous a été confirmé.")
  end

  it "allows adding a relative", js: true do
    time = Time.zone.now.change(hour: 9, min: 0o0)
    creneaux_url = creneaux_url(starts_at: time.strftime("%Y-%m-%d %H:%M"), lieu_id: lieu.id, motif_id: passport_motif.id, public_link_organisation_id: organisation.id, duration: 50)
    visit creneaux_url

    fill_in("user_email", with: user.email)
    fill_in("password", with: user.password)
    click_button("Se connecter")

    click_link("Ajouter un proche")
    fill_in("user_first_name", with: "Alain")
    fill_in("user_last_name", with: "Mairie")
    click_button("Enregistrer")
    expect(page).to have_content("Alain MAIRIE")
    expect(User.exists?(first_name: "Alain", last_name: "Mairie")).to eq(true)

    click_button("Continuer")

    click_link("Confirmer mon RDV")
    expect(page).to have_content("Votre rendez vous a été confirmé.")
  end
end
