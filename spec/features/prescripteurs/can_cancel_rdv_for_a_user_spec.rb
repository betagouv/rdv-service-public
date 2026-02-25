RSpec.describe "un prescripteur peut annuler un rendez-vous qu’il a pris pour un usager" do
  before do
    travel_to(Time.zone.parse("2022-11-07 15:00"))
  end

  let!(:territory) { create(:territory, departement_number: "75") }
  let!(:organisation) { create(:organisation, territory: territory) }
  let!(:agent) { create(:agent, :cnfs, admin_role_in_organisations: [organisation], rdv_notifications_level: "all") }
  let(:bookable_by) { "everyone" }
  let!(:motif) do
    create(:motif, organisation: organisation, service: agent.services.first, bookable_by: bookable_by, instruction_for_rdv: "Instructions après confirmation", name: "Formation emails")
  end
  let!(:lieu) { create(:lieu, organisation: organisation, name: "Bureau") }
  let!(:plage_ouverture) { create(:plage_ouverture, organisation: organisation, agent: agent, motifs: [motif], lieu: lieu) }

  it "lorsqu’il vient de prendre le rendez-vous" do
    visit "http://www.rdv-aide-numerique-test.localhost/org/#{organisation.id}"

    click_on "Formation emails" # choix du motif
    click_on lieu.name
    click_on "08:00" # choix du créneau
    click_on "Je suis un prescripteur qui oriente un bénéficiaire" # page de login

    fill_in "Votre prénom", with: "Alex"
    fill_in "Votre nom", with: "Prescripteur"
    fill_in "Votre email professionnel", with: "alex@prescripteur.fr"
    fill_in "Votre numéro de téléphone", with: "0611223344"
    click_on "Continuer"

    expect(page).to have_content("Prescripteur : Alex PRESCRIPTEUR")
    fill_in "Prénom", with: "Patricia"
    fill_in "Nom", with: "Duroy"
    fill_in "Téléphone", with: "0611223344"

    expect { click_on "Confirmer le rendez-vous" }.to change(Rdv, :count).by(1).and(change(User, :count).by(1))

    expect(page).to have_content("Rendez-vous confirmé")

    # Sur la page de confirmation, le prescripteur doit pouvoir annuler le rdv
    click_on "Annuler le rendez-vous"

    expect(page).to have_content("Le rendez-vous a bien été annulé.")

    expect(Rdv.last.status).to eq("excused")
    expect(Rdv.last.versions.last.whodunnit).to eq("[Prescripteur] Alex PRESCRIPTEUR")
    expect_sms_enqueued(phone_number: Rdv.last.users.first.phone_number_formatted, content: /a été annulé./)
  end

  it "lorsqu’il revient plus tard via son lien de confirmation" do
    prescripteur = build(:prescripteur)
    rdv = create(:rdv, created_by: prescripteur)

    visit prescripteur_show_path(token: prescripteur.token)

    click_on "Annuler le rendez-vous"

    expect(page).to have_content("Le rendez-vous a bien été annulé.")

    expect(Rdv.last.status).to eq("excused")
    expect(Rdv.last.versions.last.whodunnit).to eq(prescripteur.name_for_paper_trail)
    expect_sms_enqueued(phone_number: rdv.users.first.phone_number_formatted, content: /a été annulé./)
  end
end
