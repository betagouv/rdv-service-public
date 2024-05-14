RSpec.describe "User can search rdv on rdv service public" do
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

  it "allows booking a rdv" do
    visit "http://www.rdv-mairie-test.localhost/org/#{organisation.id}"
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
end
