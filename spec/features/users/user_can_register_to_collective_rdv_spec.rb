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
  let!(:rdv) { create(:rdv, motif: motif, agents: [agent], organisation: organisation, lieu: lieu1) }
  let!(:user) { create(:user, phone_number: "+33601010101", email: "frederique@example.com") }
  let!(:invited_user) { create(:user) }
  let!(:rdv2) { create(:rdv, motif: motif2, agents: [agent], organisation: organisation, lieu: lieu2) }
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

  def motif_selector
    expect(page).to have_content("Sélectionnez le motif de votre RDV :")
    click_link(motif.name)
    # Restriction modal
    expect(page).to have_content(motif.restriction_for_rdv)
    click_link("Accepter", match: :first)
  end

  def lieu_selector
    expect(page).to have_content("Sélectionnez un lieu de RDV :")
    click_link("Prochaine disponibilité")
  end

  def expect_notifications_for(user)
    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.map(&:to).flatten).to match_array([agent.email, user.email])
  end

  def expect_webhooks_for(user)
    expect(WebMock).to(have_requested(:post, "https://example.com/").with do |req|
      JSON.parse(req.body)["data"]["rdvs_users"].map { |rdvs_user| rdvs_user["user"]["id"] == user.id }
    end.at_least_once)
  end

  context "with a signed in user" do
    it "works" do
      login_as(user, scope: :user)
      visit root_path(params)
      motif_selector
      lieu_selector

      # Participation and back buttons
      expect do
        click_link("S'inscrire")
        click_link("Revenir en arrière")
        click_link("S'inscrire")
        click_button("Continuer")
        click_link("Revenir en arrière")
        click_button("Continuer")
        click_button("Continuer")
        stub_request(:post, "https://example.com/")
        click_on("Confirmer ma participation")
      end.to change { rdv.reload.users.count }.from(1).to(2)
      expect(page).to have_content("Inscription confirmée")
      expect(page).to have_content("modifier") # can_change_participants?

      expect_notifications_for(user)
      expect_webhooks_for(user)

      # Change participant :
      click_link("modifier")
    end
  end

  context "with a not signed in user" do
    it "redirect to login page before subscription and follow registering process" do
      visit root_path(params)
      motif_selector
      lieu_selector
      click_link("S'inscrire")

      expect(page).to have_content("Vous devez vous connecter ou vous inscrire pour continuer.")
      fill_in("user_email", with: user.email)
      fill_in("password", with: user.password)

      click_button("Se connecter")
      click_button("Continuer")
      click_button("Continuer")
      stub_request(:post, "https://example.com/")
      click_on("Confirmer ma participation")

      expect(page).to have_content("Inscription confirmée")
      expect(rdv.reload.users.count).to eq(2)
      expect_notifications_for(user)
      expect_webhooks_for(user)
    end
  end

  context "with an invited user (Token)" do
    it "works and redirect to rdv with invitaiton_token refreshed" do
      params.merge!(invitation_token: invitation_token)
      visit prendre_rdv_path(params)

      motif_selector
      lieu_selector

      expect do
        click_link("S'inscrire")
        click_button("Continuer")
        stub_request(:post, "https://example.com/")
        click_on("Confirmer ma participation")
      end.to change { rdv.reload.users.count }.from(1).to(2)
      expect(page).to have_content("Inscription confirmée")
      expect(page).not_to have_content("modifier") # can_change_participants?
      expect(::Addressable::URI.parse(current_url).query_values).to match("invitation_token" => /^[A-Z0-9]{8}$/)

      expect_notifications_for(invited_user)
      expect_webhooks_for(invited_user)
    end
  end

  context "Other cases with logged in user" do
    it "do not display revoked or full rdvs for reservation" do
      login_as(user, scope: :user)
      visit root_path(params)

      rdv.status = "revoked"
      rdv.save
      motif_selector
      expect(page).to have_content("La prise de rendez-vous n'est pas disponible pour ce département.")

      rdv2.max_participants_count = 2
      create(:rdvs_user, rdv: rdv2)
      rdv2.save
      visit root_path(params)
      expect(page).to have_content("La prise de rendez-vous n'est pas disponible pour ce département.")
    end

    it "display message of participation if already exist" do
      login_as(user, scope: :user)
      create(:rdvs_user, rdv: rdv, user: user)
      visit root_path(params)
      motif_selector
      lieu_selector
      expect(page).to have_content("Vous êtes déjà inscrit pour cet atelier")
    end

    it "change existing excused participation for re registering process and display message" do
      login_as(user, scope: :user)
      create(:rdvs_user, rdv: rdv, user: user, status: "excused")

      visit root_path(params)
      motif_selector
      lieu_selector

      expect do
        click_link("S'inscrire")
        click_button("Continuer")
        click_button("Continuer")
        stub_request(:post, "https://example.com/")
        click_on("Confirmer ma participation")
      end.not_to change { rdv.reload.users.count }
      expect(page).to have_content("Ré-Inscription confirmée")

      expect_notifications_for(user)
      expect_webhooks_for(user)
    end

    it "display rdv with cancelled tag when participation is excused or rdv is revoked" do
      login_as(user, scope: :user)
      create(:rdvs_user, rdv: rdv, user: user, status: "excused")
      visit users_rdv_path(rdv)
      expect(page).to have_content("Annulé")
      rdv2.status = "revoked"
      rdv2.save
      visit users_rdv_path(rdv2)
      expect(page).to have_content("Annulé")
    end

    it "doesnt send notifications email to user if unchecked" do
      login_as(user, scope: :user)
      visit root_path(params)
      motif_selector
      lieu_selector

      expect do
        click_link("S'inscrire")
        uncheck "Accepte les notifications par email"
        click_button("Continuer")
        click_button("Continuer")
        stub_request(:post, "https://example.com/")
        click_on("Confirmer ma participation")
      end.to change { rdv.reload.users.count }.from(1).to(2)
      expect(page).to have_content("Inscription confirmée")

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.map(&:to).flatten).to match_array([agent.email])
    end
  end
end
