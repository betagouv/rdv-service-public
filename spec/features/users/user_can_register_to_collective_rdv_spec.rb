# frozen_string_literal: true

RSpec.describe "Adding a user to a collective RDV" do
  include Rails.application.routes.url_helpers

  before do
    stub_netsize_ok
  end

  let!(:territory) { create(:territory, departement_number: "75") }
  let!(:webhook_endpoint) { create(:webhook_endpoint, organisation: organisation, subscriptions: ["rdv"], target_url: "https://example.com") }
  let!(:organisation) { create(:organisation, territory: territory) }
  let!(:agent) { create(:agent, organisations: [organisation], rdv_notifications_level: "all") }
  let!(:service) { create(:service) }
  let!(:motif) { create(:motif, :collectif, reservable_online: true, organisation: organisation, service: service) }
  let!(:motif2) { create(:motif, :collectif, reservable_online: true, organisation: organisation, service: service) }
  let!(:lieu1) { create(:lieu, organisation: organisation) }
  let!(:lieu2) { create(:lieu, organisation: organisation) }
  let!(:rdv) { create(:rdv, :without_users, motif: motif, agents: [agent], organisation: organisation, lieu: lieu1) }
  let!(:user) { create(:user, phone_number: "+33601010101", email: "frederique@example.com") }
  let!(:invited_user) { create(:user) }
  let!(:rdv2) { create(:rdv, :without_users, motif: motif2, agents: [agent], organisation: organisation, lieu: lieu2) }
  let!(:invitation_token) do
    invited_user.invite! { |u| u.skip_invitation = true }
    invited_user.raw_invitation_token
  end

  let(:params) do
    {
      address: "Paris 75001",
      city_code: "75056",
      departement: "75",
      latitude: "48.859",
      longitude: "2.347",
    }
  end

  def basic_participation_process
    # Motif selector
    expect(page).to have_content("Sélectionnez le motif de votre RDV :")
    click_link(motif.name)
    # Restriction modal
    expect(page).to have_content(motif.restriction_for_rdv)
    click_link("Accepter", match: :first)
    # Lieu selector
    expect(page).to have_content("Sélectionnez un lieu de RDV :")
    click_link("Prochaine disponibilité")

    # Participation and back buttons
    expect do
      click_link("S'inscrire")
      click_link("Revenir en arrière")
      click_link("S'inscrire")
      # TODO User change on form

      click_button("Continuer")
      click_link("Revenir en arrière")
      # TODO test modifier
      click_button("Continuer")
      click_button("Continuer")
      stub_request(:post, "https://example.com/")
      click_on("Confirmer ma participation")
    end.to change { rdv.reload.users.count }.from(0).to(1)
    expect(page).to have_content("Inscription confirmée")

    # Expect Notifications
    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.map(&:to).flatten).to match_array([agent.email, user.email])

    # Expect Webhooks
    rdv.reload
    expect(WebMock).to(have_requested(:post, "https://example.com/").with do |req|
      JSON.parse(req.body)["data"]["users"].map { |user| user["id"] } == [user.id]
    end)
  end

  context "with a signed in user" do
    it "works" do
      login_as(user, scope: :user)
      visit root_path(params)
      basic_participation_process
    end
  end

  context "with a not signed in user" do
    it "redirect to login page before subscription" do
      visit root_path(params)
      # Motif selector
      expect(page).to have_content("Sélectionnez le motif de votre RDV :")
      click_link(motif.name)
      # Restriction modal
      expect(page).to have_content(motif.restriction_for_rdv)
      click_link("Accepter", match: :first)
      # Lieu selector
      expect(page).to have_content("Sélectionnez un lieu de RDV :")
      click_link("Prochaine disponibilité")
      click_link("S'inscrire")

      expect(page).to have_content("Vous devez vous connecter ou vous inscrire pour continuer.")

      fill_in("user_email", with: user.email)
      fill_in("password", with: user.password)

      click_button("Se connecter")
      click_button("Continuer")
      click_button("Continuer")
      click_on("Confirmer ma participation")

      expect(page).to have_content("Inscription confirmée")
      expect(rdv.reload.users.count).to eq(1)
    end
  end

  context "with an invited user (Token)" do
    it "works" do
      params.merge!(invitation_token: invitation_token)
      visit prendre_rdv_path(params)

      expect(page).to have_content("Sélectionnez le motif de votre RDV :")
      click_link(motif.name)
      expect(page).to have_content(motif.restriction_for_rdv)
      click_link("Accepter", match: :first)
      expect(page).to have_content("Sélectionnez un lieu de RDV :")
      click_link("Prochaine disponibilité")

      expect do
        click_link("S'inscrire")
        click_button("Continuer")
        stub_request(:post, "https://example.com/")
        click_on("Confirmer ma participation")
      end.to change { rdv.reload.users.count }.from(0).to(1)
      expect(page).to have_content("Inscription confirmée")
      expect(::Addressable::URI.parse(current_url).query_values).to match("invitation_token" => /^[A-Z0-9]{8}$/)
      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.map(&:to).flatten).to match_array([agent.email, invited_user.email])

      rdv.reload
      expect(WebMock).to(have_requested(:post, "https://example.com/").with do |req|
        JSON.parse(req.body)["data"]["users"].map { |user| user["id"] } == [invited_user.id]
      end)
    end
  end

#  - Ne pas afficher un rdv revoked ou full ou passé ou pas ouvert à la réservation
#  - Ne pas pouvoir prendre rdv sur un rdv non collectif (au niveau du controlleur) override des params avec un id de rdv non collectif
#  - Message pour une participation existante
#  - Message pour un changement de status
#  - RDV annulé vérifier le tag
#  - tester le user helper : can_change_participants?(rdv) pour les non invité et invité (no 'modifier' dans le resumé)
#  - Tester tout les boutons "modifier"

end
