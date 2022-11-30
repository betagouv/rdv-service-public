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
  let!(:logged_user) { create(:user, phone_number: "+33601010101", email: "frederique@example.com") }
  let!(:invited_user) { create(:user, last_name: "INVITE") }
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

  def select_motif
    expect(page).to have_content("Sélectionnez le motif de votre RDV :")
    click_link(motif.name)
    # Restriction modal
    expect(page).to have_content(motif.restriction_for_rdv)
    click_link("Accepter", match: :first)
  end

  def select_lieu
    expect(page).to have_content("Sélectionnez un lieu de RDV :")
    click_link("Prochaine disponibilité")
  end

  def expect_notifications_for(user)
    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.map(&:to).flatten).to match_array([agent.email, user.email])
  end

  def expect_webhooks_for(user)
    rdv.reload
    expect(WebMock).to(have_requested(:post, "https://example.com/").with do |req|
      JSON.parse(req.body)["data"]["users"].map { |local_user| local_user["id"] } == [user.id]
    end.at_least_once)
  end

  context "with a signed in user" do
    it "works" do
      login_as(logged_user, scope: :user)
      visit root_path(params)
      select_motif
      select_lieu

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
      end.to change { rdv.reload.users.count }.from(0).to(1)
      expect(page).to have_content("Inscription confirmée")
      expect(page).to have_content("modifier") # can_change_participants?

      expect_notifications_for(logged_user)
      expect_webhooks_for(logged_user)

      # Change participant :
      click_link("modifier")
      # Todo
    end
  end

  context "with a not signed in user" do
    it "redirect to login page before subscription and follow registering process" do
      visit root_path(params)
      select_motif
      select_lieu
      click_link("S'inscrire")

      expect(page).to have_content("Vous devez vous connecter ou vous inscrire pour continuer.")
      fill_in("user_email", with: logged_user.email)
      fill_in("password", with: logged_user.password)

      click_button("Se connecter")
      click_button("Continuer")
      click_button("Continuer")
      stub_request(:post, "https://example.com/")
      click_on("Confirmer ma participation")

      expect(page).to have_content("Inscription confirmée")
      expect(rdv.reload.users.count).to eq(1)
      expect_notifications_for(logged_user)
      expect_webhooks_for(logged_user)
    end
  end

  context "with an invited user (Token)" do
    it "works and redirect to rdv with invitaiton_token refreshed" do
      params.merge!(invitation_token: invitation_token)
      visit prendre_rdv_path(params)

      select_motif
      select_lieu

      expect do
        click_link("S'inscrire")
        click_button("Continuer")
        stub_request(:post, "https://example.com/")
        click_on("Confirmer ma participation")
      end.to change { rdv.reload.users.count }.from(0).to(1)
      expect(page).to have_content("Inscription confirmée")
      expect(page).not_to have_content("modifier") # can_change_participants?
      expect(::Addressable::URI.parse(current_url).query_values).to match("invitation_token" => /^[A-Z0-9]{8}$/)

      expect_notifications_for(invited_user)
      expect_webhooks_for(invited_user)
    end
  end

  context "Specific cases" do
    %w[invited logged].each do |user_type|
      it "do not display revoked or full rdvs for reservation with #{user_type} user" do
        user = user_type == "invited" ? invited_user : logged_user
        if user_type == "invited"
          params.merge!(invitation_token: invitation_token)
        else
          login_as(user, scope: :user)
        end
        visit root_path(params)

        rdv.status = "revoked"
        rdv.save
        select_motif
        expect(page).to have_content("Nous n'avons pas trouvé de créneaux pour votre motif.")

        rdv2.max_participants_count = 2
        create(:rdvs_user, rdv: rdv2)
        create(:rdvs_user, rdv: rdv2)
        rdv2.save
        visit root_path(params)
        expect(page).to have_content("Nous n'avons pas trouvé de créneaux pour votre motif.")
      end

      it "display message of participation if already exist with #{user_type} user" do
        user = user_type == "invited" ? invited_user : logged_user
        if user_type == "invited"
          params.merge!(invitation_token: invitation_token)
        else
          login_as(user, scope: :user)
        end
        create(:rdvs_user, rdv: rdv, user: user)
        visit root_path(params)
        select_motif
        select_lieu
        expect(page).to have_content("Vous êtes déjà inscrit pour cet atelier")
      end

      it "change existing excused participation for re registering process and display message with #{user_type} user" do
        user = user_type == "invited" ? invited_user : logged_user
        if user_type == "invited"
          params.merge!(invitation_token: invitation_token)
        else
          login_as(user, scope: :user)
        end
        create(:rdvs_user, rdv: rdv, user: user, status: "excused")

        visit root_path(params)
        select_motif
        select_lieu

        expect do
          click_link("S'inscrire")
          click_button("Continuer")
          if page.has_button?("Continuer")
            page.click_button("Continuer")
          end
          stub_request(:post, "https://example.com/")
          click_on("Confirmer ma participation")
        end.not_to change { rdv.reload.users.count }
        expect(page).to have_content("Ré-Inscription confirmée")

        expect_notifications_for(user)
        expect_webhooks_for(user)
      end

      it "display rdv with cancelled tag when participation is excused or rdv is revoked with #{user_type} user", js: true do
        user = user_type == "invited" ? invited_user : logged_user
        if user_type == "invited"
          params.merge!(invitation_token: invitation_token)
          visit root_path(params)
        else
          login_as(user, scope: :user)
        end

        create(:rdvs_user, rdv: rdv, user: user, status: "excused")

        if user_type == "invited"
          visit users_rdv_path(rdv, invitation_token: rdv.rdv_user_token(user.id))
          fill_in(:letter0, with: "I")
          fill_in(:letter1, with: "N")
          fill_in(:letter2, with: "V")
        else
          visit users_rdv_path(rdv)
        end

        expect(page).to have_content("Annulé")
        create(:rdvs_user, rdv: rdv2, user: user, status: "revoked")
        rdv2.status = "revoked"
        rdv2.save

        if user_type == "invited"
          visit users_rdv_path(rdv2, invitation_token: rdv2.rdv_user_token(user.id))
        else
          visit users_rdv_path(rdv)
        end

        expect(page).to have_content("Annulé")
      end

      it "doesnt send notifications email to user if unchecked with #{user_type} user" do
        user = user_type == "invited" ? invited_user : logged_user
        if user_type == "invited"
          params.merge!(invitation_token: invitation_token)
        else
          login_as(user, scope: :user)
        end
        visit root_path(params)
        select_motif
        select_lieu

        expect do
          click_link("S'inscrire")
          uncheck "Accepte les notifications par email"
          click_button("Continuer")
          if page.has_button?("Continuer")
            page.click_button("Continuer")
          end
          stub_request(:post, "https://example.com/")
          click_on("Confirmer ma participation")
        end.to change { rdv.reload.users.count }.from(0).to(1)
        expect(page).to have_content("Inscription confirmée")

        perform_enqueued_jobs
        expect(ActionMailer::Base.deliveries.map(&:to).flatten).to match_array([agent.email])
      end
    end
  end
end
