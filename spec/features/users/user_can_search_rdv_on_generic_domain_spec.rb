# frozen_string_literal: true

describe "User can search rdv on generic domain name with an organisation that is not a mairie, and not get any mairie-specific logic" do
  let(:now) { Time.zone.parse("2021-12-13 8:00") }
  let!(:territory) { create(:territory, departement_number: "MA") }
  let!(:organisation) { create(:organisation, :with_contact, territory: territory, verticale: :rdv_aide_numerique) }
  let!(:motif) do
    create(:motif, name: "RDV avec l'équipe Démarches Simplifiées", organisation: organisation, restriction_for_rdv: nil, location_type: :phone,
                   default_duration_in_min: 25)
  end

  let(:user) { create(:user, email: "jeansaas@example.com") }

  def json_response
    JSON.parse(page.html)
  end

  before do
    default_url_options[:host] = "http://www.rdv-mairie-test.localhost"
    travel_to(now)
    create(:plage_ouverture, :no_recurrence, first_day: now, motifs: [motif], organisation: organisation, start_time: Tod::TimeOfDay(9), end_time: Tod::TimeOfDay.new(10))
  end

  it "allows booking a rdv" do
    visit public_link_to_org_url(organisation_id: organisation.id, org_slug: organisation.slug)
    click_on("9:00")

    fill_in("user_email", with: user.email)
    fill_in("password", with: user.password)
    click_button("Se connecter")

    expect(page).not_to have_field("Numéro de pré-demande ANTS")
    click_button("Continuer")

    click_button("Continuer")
    click_link("Confirmer mon RDV")
    expect(page).to have_content("Votre rendez vous a été confirmé.")
    expect(Rdv.last.users.first).to eq user
  end

  it "can add a relative with their ants_pre_demande_number", js: true do
    time = Time.zone.now.change(hour: 9, min: 0o0)
    creneaux_url = creneaux_url(starts_at: time.strftime("%Y-%m-%d %H:%M"), lieu_id: lieu.id, motif_id: passport_motif.id, public_link_organisation_id: organisation.id, duration: 50)
    visit creneaux_url

    fill_in("user_email", with: user.email)
    fill_in("password", with: user.password)
    click_button("Se connecter")

    fill_in("user_ants_pre_demande_number", with: "5544332211")
    click_button("Continuer")

    click_link("Ajouter un proche")
    fill_in("user_first_name", with: "Alain")
    fill_in("user_last_name", with: "Mairie")
    fill_in("user_ants_pre_demande_number", with: "5544332211")
    click_button("Enregistrer")
    expect(page).to have_content("Alain MAIRIE")
    expect(User.exists?(first_name: "Alain", last_name: "Mairie", ants_pre_demande_number: "5544332211")).to eq(true)

    click_button("Continuer")

    click_link("Confirmer mon RDV")
    expect(page).to have_content("Votre rendez vous a été confirmé.")
  end
end
