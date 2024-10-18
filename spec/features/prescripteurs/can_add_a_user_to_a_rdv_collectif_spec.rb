RSpec.describe "prescripteur can add a user to a RDV collectif" do
  before do
    travel_to(Time.zone.parse("2022-11-07 15:00"))
  end

  let!(:organisation) { create(:organisation) }
  let!(:lieu) { create(:lieu, organisation: organisation, name: "Bureau") }
  let!(:agent) { create(:agent, :cnfs, admin_role_in_organisations: [organisation], rdv_notifications_level: "all") }
  let!(:motif_collectif) do
    create(:motif, :collectif, organisation: organisation, service: agent.services.first, instruction_for_rdv: "Instructions après confirmation", name: "Formation emails")
  end
  let!(:rdv_collectif) do
    create(
      :rdv,
      :without_users,
      organisation: organisation,
      motif: motif_collectif,
      agents: [agent],
      lieu: lieu,
      starts_at: Time.zone.parse("2022-11-09 10:00"),
      max_participants_count: 2
    )
  end

  it "works" do
    visit "http://www.rdv-aide-numerique-test.localhost/org/#{organisation.id}"
    click_on "Formation emails" # choix du motif

    click_on "Prochaine disponibilité le" # choix du lieu
    click_on "S'inscrire" # choix du RDV collectif
    click_on "Je suis un prescripteur qui oriente un bénéficiaire" # page de login

    fill_in "Votre prénom", with: "Alex"
    fill_in "Votre nom", with: "Prescripteur"
    fill_in "Votre email professionnel", with: "alex@prescripteur.fr"
    fill_in "Votre numéro de téléphone", with: "0611223344"
    click_on "Continuer"

    expect(page).to have_content("Prescripteur : Alex PRESCRIPTEUR")
    fill_in "Prénom", with: "Patricia"
    fill_in "Nom", with: "Duroy"

    click_on "Confirmer le rendez-vous"
    expect(page).to have_content("Sans numéro de téléphone, aucune notification ne sera envoyée au bénéficiaire")
    click_on "Annuler et modifier"
    fill_in "Téléphone", with: "0123456789"
    click_on "Confirmer le rendez-vous"

    expect(page).to have_content("Téléphone ne permet pas de recevoir des SMS")
    fill_in "Téléphone", with: "0611223344"

    expect { click_on "Confirmer le rendez-vous" }.to change { rdv_collectif.users.count }.by(1).and(change(User, :count).by(1))

    expect(page).to have_content("Rendez-vous confirmé")
    expect(page).to have_content("Patricia DUROY")
    expect(page).to have_content("Le mercredi 09 novembre 2022 à 10h00")
    expect(page).to have_content("Bureau")
    expect(page).to have_content("Instructions après confirmation")

    rdv_collectif.reload
    expect(rdv_collectif.agents).to eq([agent])
    expect(rdv_collectif.users.size).to eq(1)
    expect(rdv_collectif.users.first).to have_attributes(
      full_name: "Patricia DUROY",
      created_through: "prescripteur",
      phone_number: "0611223344",
      organisations: [organisation]
    )
    expect(rdv_collectif.participations.first.created_by).to have_attributes(
      first_name: "Alex",
      last_name: "Prescripteur",
      email: "alex@prescripteur.fr",
      phone_number: "0611223344"
    )

    perform_enqueued_jobs(queue: "mailers")
    expect(email_sent_to(agent.email).subject).to include("Nouvelle participation au RDV collectif sur votre agenda RDV Solidarités")
    expect(email_sent_to("alex@prescripteur.fr").subject).to include("RDV confirmé")
    expect(email_sent_to("alex@prescripteur.fr").body).to include("RDV Aide Numérique")

    expect(enqueued_jobs.first["job_class"]).to eq("SmsJob")
    expect(enqueued_jobs.first["arguments"][0]["phone_number"]).to eq("+33611223344")
  end

  context "when creneau is taken by someone else during booking process" do
    let!(:fallback_rdv_collectif_2_hours_later) do
      create(:rdv, :without_users, motif: motif_collectif, agents: [agent], lieu: lieu, starts_at: rdv_collectif.starts_at + 2.hours)
    end

    it "redirects to creneau search with error message" do
      visit "http://www.rdv-aide-numerique-test.localhost/org/#{organisation.id}"

      click_on "Formation emails" # choix du motif
      click_on "Prochaine disponibilité le" # choix du lieu
      click_on "S'inscrire", match: :first # choix du RDV collectif
      click_on "Je suis un prescripteur qui oriente un bénéficiaire" # page de login
      fill_in "Votre prénom", with: "Alex"
      fill_in "Votre nom", with: "Prescripteur"
      fill_in "Votre email professionnel", with: "alex@prescripteur.fr"
      fill_in "Votre numéro de téléphone", with: "0611223344"
      click_on "Continuer"
      fill_in "Prénom", with: "Patricia"
      fill_in "Nom", with: "Duroy"
      fill_in "Téléphone", with: "0611223344"

      # On simule que toutes les places sont prises
      create(:participation, rdv: rdv_collectif)
      create(:participation, rdv: rdv_collectif)
      click_on "Confirmer le rendez-vous"
      expect(page).to have_content("Ce créneau n'est plus disponible. Veuillez en choisir un autre.")

      # Dans ce cas, retour à l'étape de choix d'un RDV collectif pour ce motif
      click_on "S'inscrire" # On s'inscrit à l'autre RDV collectif, le seul restant de la liste

      # On constate que le formulaire de prescripteur est pré-rempli
      expect(page).to have_field("Votre prénom", with: "Alex")
      expect(page).to have_field("Votre nom", with: "Prescripteur")
    end
  end
end
