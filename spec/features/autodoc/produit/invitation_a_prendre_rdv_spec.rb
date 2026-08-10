RSpec.describe "Invitation à prendre rendez-vous", js: true do
  let!(:motif) { create(:motif, name: "Suivi de dossier", organisation:) }
  let(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [motif.organisation]) }
  let!(:user) { create(:user, organisations: [organisation]) }
  let(:lieu) { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, organisation: organisation) }

  before { login_as(agent, scope: :agent) }

  specify do
    doc = Autodoc.start_scenario("Invitation à prendre rendez-vous", self, category: "3) Produit", accessibility_checks: false)

    doc.start_section("Côté agent")

    doc.add_text("La fonctionnalité est cachée derrière un feature flag")
    agent.enable_feature!("rdv_plan_invitations")

    visit calendar_admin_organisation_planning_plage_ouvertures_path(organisation.id)

    doc.add_screenshot(
      page,
      text: "J'ai une plage d'ouverture pour un motif qui n'est pas réservable en ligne",
      wait_for: "Planning de"
    )

    visit admin_organisation_user_path(organisation.id, user.id)

    doc.add_screenshot(
      page,
      text: "Je vais sur la page de l'usager, et je clique sur Trouver un rendez-vous",
      wait_for: "Informations générales"
    )

    click_on "Trouver un RDV pour l’usager"

    select("Suivi de dossier", from: "Motif")

    doc.add_screenshot(
      page,
      text: "Je fais une recherche de créneaux pour mon motif",
      wait_for: "Trouver un RDV"
    )

    click_on "Afficher les créneaux"

    doc.add_screenshot(
      page,
      text: "En dessous de la liste des créneaux, on me proposer de laisser l'usager choisir son créneau. Je clique sur ce lien",
      wait_for: "Vous pouvez aussi inviter l'usager à choisir son créneau."
    )

    click_on "inviter l'usager à choisir son créneau"

    doc.add_screenshot(
      page,
      text: "On me récapitule les infos. Je clique sur Envoyer l'invitation",
      wait_for: "Nouvelle invitation"
    )

    click_on "Envoyer l'invitation"

    doc.add_screenshot(
      page,
      text: "J'ai un message de confirmation",
      wait_for: "Vous avez invité"
    )

    doc.start_section("Côté usager")
  end
end
