# frozen_string_literal: true

describe "User can search rdv on rdv mairie" do
  include_context "rdv_mairie_api_authentication"

  let(:now) { Time.zone.parse("2021-12-13 8:00") }
  let!(:territory95) { create(:territory, departement_number: "95") }
  let!(:organisation) { create(:organisation, :with_contact, territory: territory95, verticale: :rdv_mairie) }
  let(:service) { create(:service) }
  let!(:motif) { create(:motif, name: "Passeport", bookable_publicly: true, organisation: organisation, restriction_for_rdv: nil, service: service) }
  let!(:lieu) { create(:lieu, organisation: organisation, name: "Mairie de Sannois", address: "15 Place du Général Leclerc, Sannois, 95110") }
  let(:user) { create(:user, email: "jeanmairie@example.com") }
  let(:ants_pre_demande_number) { "1122334455" }

  def json_response
    JSON.parse(page.html)
  end

  before do
    default_url_options[:host] = "http://www.rdv-mairie-test.localhost"
  end

  before do
    travel_to(now)
    create(:plage_ouverture, :no_recurrence, first_day: now, motifs: [motif], lieu: lieu, organisation: organisation, start_time: Tod::TimeOfDay(9), end_time: Tod::TimeOfDay.new(10))
  end

  it "default" do
    visit api_ants_getManagedMeetingPoints_url
    lieux_ids = json_response.map { |lieu_data| lieu_data["id"] }
    expect(lieux_ids).to eq([lieu.id.to_s])

    visit api_ants_availableTimeSlots_url(
      meeting_point_ids: lieux_ids,
      start_date: Date.yesterday,
      end_date: Date.tomorrow
    )

    time = Time.zone.now.change(hour: 9, min: 0o0)

    expect(json_response).to eq(
      {
        lieu.id.to_s => [
          {
            "datetime" => time.strftime("%Y-%m-%dT%H:%MZ"),
            "callback_url" => creneaux_url(starts_at: time.strftime("%Y-%m-%d %H:%M"), lieu_id: lieu.id, motif_id: motif.id),
          },
        ],
      }
    )
    creneaux_url = json_response[lieu.id.to_s].first["callback_url"]

    visit_public_creneaux_link(creneaux_url)
    login_and_confirm_rdv
  end

  private

  def visit_public_creneaux_link(creneaux_url)
    visit creneaux_url

    expect(page).to have_current_path("/users/sign_in")
    expect(page).to have_content("Vous devez vous connecter ou vous inscrire pour continuer")
    expect(page).to have_content("Motif : Passeport")
    expect(page).to have_content("Lieu : Mairie de Sannois (15 Place du Général Leclerc, Sannois, 95110)")
    expect(page).to have_content("Date du rendez-vous : lundi 13 décembre 2021 à 09h00 (45 minutes)")
  end

  def login_and_confirm_rdv
    fill_in("user_email", with: user.email)
    fill_in("password", with: user.password)
    click_button("Se connecter")

    expect(page).to have_field("Numéro de pré-demande ANTS")
    fill_in("user_ants_pre_demande_number", with: ants_pre_demande_number)
    click_button("Continuer")
    click_button("Continuer")
    click_link("Confirmer mon RDV")
    expect(page).to have_content("Votre rendez vous a été confirmé.")
    expect(user.reload.ants_pre_demande_number).to eq(ants_pre_demande_number)
  end
end
