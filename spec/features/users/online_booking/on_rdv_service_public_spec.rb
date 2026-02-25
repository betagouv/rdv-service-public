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
    default_url_options[:host] = "http://www.rdv-service-public-test.localhost"
    travel_to(now)
    create(:plage_ouverture, :no_recurrence, first_day: now, motifs: [demarches_simplifies_motif], lieu: lieu, organisation: organisation, start_time: Tod::TimeOfDay(9),
                                             end_time: Tod::TimeOfDay.new(10))
  end

  it "allows booking a rdv" do
    visit "http://www.rdv-service-public-test.localhost/org/#{organisation.public_link_id}"
    click_on("Clarification du dossier")
    click_on(lieu.name) # choix du lieu

    first(:link, "09:00").click
    expect(page).to have_current_path("/users/sign_in")

    login_via_6_digit_code(user.email)

    expect(page).not_to have_field("Numéro de pré-demande ANTS")

    click_button("Continuer")
    click_button("Continuer")
    click_link("Confirmer mon RDV")
    expect(page).to have_content("Votre rendez vous a été confirmé.")
  end

  describe "quand l’organisation n’accepte que les prises de RDV par ProConnect" do
    let!(:territory) { create(:territory, id: 2) } # Pour le moment on n’accepte que ProConnect pour le territoire qui a l’id 2
    let!(:organisation) { create(:organisation, territory:, verticale: :rdv_mairie) }
    let!(:motif) { create(:motif, :by_phone, organisation:) }
    let!(:lieu) { create(:lieu, organisation:) }
    let!(:plage_ouverture) do
      create(:plage_ouverture, :weekdays, first_day: Date.parse("2024-11-04"), motifs: [motif], lieu: lieu, organisation:, start_time: Tod::TimeOfDay.new(8), end_time: Tod::TimeOfDay.new(12))
    end

    before { travel_to Date.parse("2024-11-03").in_time_zone + 8.hours }
    before { login_as(user, scope: :user) }
    before { allow(organisation).to receive(:online_booking_only_sso?).and_return(true) }

    context "si le user à un sub ProConnect" do
      let!(:user) { create(:user, :using_pro_connect, organisations: [organisation]) }

      it "permet de prendre un RDV" do
        visit(new_users_rdv_wizard_step_path(step: 1, departement: "24", motif_id: motif.id, lieu_id: lieu.id, starts_at: Time.zone.parse("2024-11-05 08:00")))
        expect(page).to have_content("Vos informations")
        click_on("Continuer")
        click_on("Confirmer mon RDV")
        expect(page).to have_content "Votre rendez vous a été confirmé."
      end
    end

    context "si le user n’a pas de sub ProConnect" do
      let!(:user) { create(:user, organisations: [organisation]) }

      it "permet de prendre un RDV" do
        visit(new_users_rdv_wizard_step_path(step: 1, departement: "24", motif_id: motif.id, lieu_id: lieu.id, starts_at: Time.zone.parse("2024-11-05 08:00")))
        expect(page).to have_content("Vos informations")
        click_on("Continuer")
        click_on("Continuer")
        click_on("Confirmer mon RDV")
        expect(page).to have_content "Ce motif de rendez-vous est réservé aux professionnels. " \
                                     "Si vous êtes un professionnel et que vous souhaitez prendre rendez-vous, merci de vous déconnecter et de recommencer votre demande en utilisant ProConnect."
      end
    end
  end
end
