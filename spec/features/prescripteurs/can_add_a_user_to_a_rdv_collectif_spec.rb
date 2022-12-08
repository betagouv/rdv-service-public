# frozen_string_literal: true

RSpec.describe "prescripteur can add a user to a RDV collectif" do
  before do
    travel_to(Time.zone.parse("2022-11-07 15:00"))
  end

  let!(:organisation) { create(:organisation) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:agent) { create(:agent, :cnfs, admin_role_in_organisations: [organisation], rdv_notifications_level: "all") }
  let!(:motif_collectif) { create(:motif, :collectif, organisation: organisation, service: agent.service, reservable_online: true) }
  let!(:rdv_collectif) do
    create(
      :rdv,
      motif: motif_collectif,
      agents: [agent],
      lieu: lieu,
      starts_at: Time.zone.parse("2022-11-09 10:00"),
      max_participants_count: 2
    )
  end

  it "works" do
    visit "http://www.rdv-aide-numerique-test.localhost/org/#{organisation.id}"

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
    fill_in "Téléphone", with: "0611223344"

    # Dans ce cas, retour à l'étape de choix du lieu
    click_on "Prochaine disponibilité le"
    click_on "08:45"
    click_on "Je suis un prescripteur qui oriente un bénéficiaire"

    # On constate que le formulaire de prescripteur est pré-rempli
    expect(page).to have_field("Votre prénom", with: "Alex")
    expect(page).to have_field("Votre nom", with: "Prescripteur")
    click_on "Continuer"

    expect(page).to have_content("Prescripteur : Alex PRESCRIPTEUR")
    fill_in "Prénom", with: "Patricia"
    fill_in "Nom", with: "Duroy"
    click_on "Confirmer le rendez-vous"
    expect(page).to have_content("Sans numéro de téléphone, aucune notification ne sera envoyée au bénéficiaire")
    click_on "Annuler et modifier"
    fill_in "Téléphone", with: "0123456789"

    # On simule que toutes les places sont prises
    create(:rdvs_user, rdv: rdv_collectif)
    create(:rdvs_user, rdv: rdv_collectif)
    click_on "Confirmer le rendez-vous"

    expect(page).to have_content("Ce créneau n'est plus disponible. Veuillez en choisir un autre.")

    expect(page).to have_content("Téléphone ne permet pas de recevoir des SMS")
    fill_in "Téléphone", with: "0611223344"

    expect { click_on "Confirmer le rendez-vous" }.to change(Rdv, :count).by(1).and(change(User, :count).by(1))

    expect(page).to have_content("Rendez-vous confirmé")
    expect(page).to have_content("Patricia DUROY")
    expect(page).to have_content("Le mardi 15 novembre 2022 à 08h45")
    expect(page).to have_content("Bureau")
    expect(page).to have_content("Instructions après confirmation")

    created_rdv = Rdv.last
    expect(created_rdv.agents).to eq([agent])
    expect(created_rdv.rdvs_users.size).to eq(1)
    expect(created_rdv.rdvs_users.first.user).to have_attributes(
      full_name: "Patricia DUROY",
      created_through: "prescripteur",
      phone_number: "0611223344",
      organisations: [organisation]
    )
    expect(created_rdv.rdvs_users.first.prescripteur).to have_attributes(
      first_name: "Alex",
      last_name: "Prescripteur",
      email: "alex@prescripteur.fr",
      phone_number: "0611223344"
    )
    expect(created_rdv.created_by).to eq("prescripteur")

    perform_enqueued_jobs(queue: "mailers")
    expect(email_sent_to(agent.email).subject).to include("Nouveau RDV ajouté sur votre agenda RDV Solidarités")
    expect(email_sent_to("alex@prescripteur.fr").subject).to include("RDV confirmé")
    expect(email_sent_to("alex@prescripteur.fr").body).to include("RDV Aide Numérique")

    expect(enqueued_jobs.first["job_class"]).to eq("SmsJob")
    expect(enqueued_jobs.first["arguments"][0]["phone_number"]).to eq("+33611223344")
  end

  xit "sends notifications to the user, agent and prescripteur" do
    raise "write that spec"
  end

  xit "allows prescripteur to make changes for a few minutes" do
    raise "write this other spec"
  end

  xit "prevents hacker from changing motif_id in URL to create illegitimate RDV" do
    raise "write that one spec"
  end

  context "when creneau is taken by someone else during booking process" do
    xit "redirects to creneau search with error message" do
      raise "write spec"
    end
  end
end
