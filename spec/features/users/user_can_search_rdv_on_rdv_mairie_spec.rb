# frozen_string_literal: true

describe "User can search rdv on rdv mairie" do
  include_context "rdv_mairie_api_authentication"

  let(:now) { Time.zone.parse("2021-12-13 8:00") }
  let!(:territory) { create(:territory, departement_number: "MA") }
  let!(:organisation) { create(:organisation, :with_contact, territory: territory, verticale: :rdv_mairie) }
  let(:service) { create(:service) }
  let!(:cni_motif) do
    create(:motif, name: "Carte d'identité", organisation: organisation, restriction_for_rdv: nil, service: service, motif_category: cni_motif_category)
  end
  let!(:passport_motif) do
    create(:motif, name: "Passeport", organisation: organisation, restriction_for_rdv: nil, service: service, motif_category: passport_motif_category)
  end

  let!(:cni_motif_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME) }
  let!(:passport_motif_category) { create(:motif_category, name: Api::Ants::EditorController::PASSPORT_MOTIF_CATEGORY_NAME) }
  let!(:lieu) { create(:lieu, organisation: organisation, name: "Mairie de Sannois", address: "15 Place du Général Leclerc, Sannois, 95110") }
  let(:user) { create(:user, email: "jeanmairie@example.com") }
  let(:ants_pre_demande_number) { "1122334455" }
  let(:invalid_ants_pre_demande_number) { "5544332211" }

  def json_response
    JSON.parse(page.html)
  end

  before do
    default_url_options[:host] = "http://www.rdv-mairie-test.localhost"
    travel_to(now)
    create(:plage_ouverture, :no_recurrence, first_day: now, motifs: [passport_motif], lieu: lieu, organisation: organisation, start_time: Tod::TimeOfDay(9), end_time: Tod::TimeOfDay.new(10))
  end

  it "allows booking a rdv through the full lifecycle of api calls" do
    visit api_ants_getManagedMeetingPoints_url
    lieux_ids = json_response.map { |lieu_data| lieu_data["id"] }
    expect(lieux_ids).to eq([lieu.id.to_s])

    visit api_ants_availableTimeSlots_url(
      meeting_point_ids: lieux_ids.first,
      start_date: Date.yesterday,
      end_date: Date.tomorrow,
      reason: "PASSPORT"
    )

    time = Time.zone.now.change(hour: 9, min: 0o0)

    expect(json_response).to eq(
      {
        lieu.id.to_s => [
          {
            "datetime" => time.strftime("%Y-%m-%dT%H:%MZ"),
            "callback_url" => creneaux_url(starts_at: time.strftime("%Y-%m-%d %H:%M"), lieu_id: lieu.id, motif_id: passport_motif.id, public_link_organisation_id: organisation.id),
          },
        ],
      }
    )
    creneaux_url = json_response[lieu.id.to_s].first["callback_url"]

    visit creneaux_url

    expect(page).to have_current_path("/users/sign_in")
    expect(page).to have_content("Vous devez vous connecter ou vous inscrire pour continuer")
    expect(page).to have_content("Motif : Passeport")
    expect(page).to have_content("Lieu : Mairie de Sannois (15 Place du Général Leclerc, Sannois, 95110)")
    expect(page).to have_content("Date du rendez-vous : lundi 13 décembre 2021 à 09h00 (45 minutes)")
    expect(page).to have_link("modifier", href: prendre_rdv_path(departement: "MA", public_link_organisation_id: organisation.id))
    expect(page).to have_link("modifier",
                              href: prendre_rdv_path(departement: "MA", motif_name_with_location_type: passport_motif.name_with_location_type, public_link_organisation_id: organisation.id))
    expect(page).to have_link("modifier",
                              href: prendre_rdv_path(departement: "MA", lieu_id: lieu.id, motif_name_with_location_type: passport_motif.name_with_location_type,
                                                     public_link_organisation_id: organisation.id))

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
