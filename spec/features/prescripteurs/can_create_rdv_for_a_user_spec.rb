# frozen_string_literal: true

RSpec.describe "prescripteur can create RDV for a user" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, :cnfs, admin_role_in_organisations: [organisation], rdv_notifications_level: "all") }
  let!(:motif) do
    create(:motif, organisation: organisation, service: agent.service, reservable_online: true, instruction_for_rdv: "Instructions après confirmation")
  end
  let!(:lieu) { create(:lieu, organisation: organisation, name: "Bureau") }
  let!(:plage_ouverture) { create(:plage_ouverture, organisation: organisation, agent: agent, motifs: [motif], lieu: lieu) }

  before do
    travel_to(Time.zone.parse("2022-11-07 15:00"))
  end

  around { |example| perform_enqueued_jobs { example.run } }

  it "works" do
    visit public_link_to_org_path(organisation_id: organisation.id)

    click_on "Prochaine disponibilité le"
    click_on "08:00"
    click_on "Je suis un prescripteur qui oriente un bénéficiaire"

    fill_in "Votre prénom", with: "Alex"
    fill_in "Votre nom", with: "Prescripteur"
    fill_in "Votre email professionnel", with: "alex@prescripteur.fr"
    fill_in "Votre numéro de téléphone", with: "0611223344"
    click_on "Continuer"

    expect(page).to have_content("Prescripteur : Alex PRESCRIPTEUR")
    fill_in "Prénom", with: "Patricia"
    fill_in "Nom", with: "Duroy"
    click_on "Confirmer le rendez-vous"

    expect(page).to have_content("Sans email ni numéro de téléphone, aucune notification ne sera envoyée au bénéficiaire")
    click_on "Annuler et modifier"
    fill_in "Email", with: "patricia_duroy@exemple.fr"
    fill_in "Téléphone", with: "0623456789"

    stub_netsize_ok
    expect { click_on "Confirmer le rendez-vous" }.to change(Rdv, :count).by(1)

    created_rdv = Rdv.last
    expect(created_rdv.users.map(&:full_name)).to eq(["Patricia DUROY"])
    expect(created_rdv.agents).to eq([agent])
    expect(created_rdv.rdvs_users.first.prescripteur).to have_attributes(
      first_name: "Alex",
      last_name: "Prescripteur",
      email: "alex@prescripteur.fr",
      phone_number: "0611223344"
    )

    expect(email_sent_to("patricia_duroy@exemple.fr").subject).to include("RDV confirmé")
    expect(email_sent_to(agent.email).subject).to include("Nouveau RDV ajouté sur votre agenda RDV Solidarités")
    expect(email_sent_to("alex@prescripteur.fr").subject).to include("RDV confirmé")
    expect(email_sent_to("alex@prescripteur.fr").body).to include("RDV Solidarités")

    expect(page).to have_content("Rendez-vous confirmé")
    expect(page).to have_content("Patricia DUROY")
    expect(page).to have_content("Le mardi 06 décembre 2022 à 08h00")
    expect(page).to have_content("Bureau")
    expect(page).to have_content("Instructions après confirmation")
  end

  context "when there already is a user with that email address" do
    before do
      create(:user, email: "patricia_duroy@exemple.fr")
    end

    it "doesn't show existing personal information but still takes the rdv" do
      raise "write this fun spec"
    end
  end

  context "when creneau is taken by someone else during booking process" do
    it "redirects to creneau search with error message" do
      raise "write spec"
    end
  end
end
