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
  let!(:motif) { create(:motif, :collectif, organisation: organisation, service: service) }
  let!(:motif2) { create(:motif, :collectif, organisation: organisation, service: service) }
  let!(:lieu1) { create(:lieu, organisation: organisation) }
  let!(:lieu2) { create(:lieu, organisation: organisation) }
  let!(:rdv) { create(:rdv, :without_users, motif: motif, agents: [agent], organisation: organisation, lieu: lieu1) }
  let!(:logged_user) { create(:user, phone_number: "+33601010101", email: "frederique@example.com") }
  let!(:invited_user) { create(:user, last_name: "INVITE") }
  let!(:other_user1) { create(:user) }
  let!(:other_user2) { create(:user) }
  let!(:rdv2) { create(:rdv, :without_users, motif: motif2, agents: [agent], organisation: organisation, lieu: lieu2) }
  let!(:invitation_token) { user.set_rdv_invitation_token!  }

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
  end

  def select_lieu
    expect(page).to have_content("Sélectionnez un lieu de RDV")
    click_link("Prochaine disponibilité")
  end

  def expect_cancel_participation
    expect do
      expect(page).to have_content("À venir")
      click_link("Annuler votre participation")
      click_link("Oui, annuler votre participation", match: :first)
      expect(page).to have_content("Participation annulée")
      expect(page).to have_content("Annulé")
    end
  end

  def expect_confirm_participation(notif: true)
    expect do
      click_link("S'inscrire")
      uncheck "Accepte les notifications par email" unless notif
      uncheck "Accepte les notifications par SMS" unless notif
      click_button("Continuer")
      if page.has_button?("Continuer")
        page.click_button("Continuer")
      end
      stub_request(:post, "https://example.com/")
      click_on("Confirmer ma participation")
      expect(page).to have_content("Participation confirmée")
    end
  end

  def expect_webhooks_for(user)
    expect(WebMock).to(have_requested(:post, "https://example.com/").with do |req|
      JSON.parse(req.body)["data"]["participations"].map { |participation| participation["user"]["id"] == user.id }
    end.at_least_once)
  end

  context "Nominal cases", js: true do
    it "with a signed in user" do
      motif.update!(restriction_for_rdv: "Test restriction")
      login_as(logged_user, scope: :user)
      visit root_path(params)
      select_motif
      select_lieu

      # Restriction for rdv modal
      expect(page).to have_content("À lire avant de prendre un rendez-vous")
      expect(page).to have_content(motif.restriction_for_rdv)
      click_link("Accepter")

      # Testing participation (with back buttons)
      expect do
        click_link("S'inscrire")
        click_link("Revenir en arrière")
        click_link("S'inscrire")
        click_button("Continuer")
        click_link("Revenir en arrière")
        sleep(1)
        click_button("Continuer")
        click_button("Continuer")
        stub_request(:post, "https://example.com/")
        click_on("Confirmer ma participation")
      end.to change { rdv.reload.users.count }.from(0).to(1)
      expect(page).to have_content("Participation confirmée")
      expect(page).to have_content("modifier") # can_change_participants?

      expect_notifications_sent_for(rdv, logged_user, :rdv_created)
      expect_webhooks_for(logged_user)
    end

    it "with a not signed in user, redirect to login page before subscription and follow registering process" do
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
      expect(page).to have_content("Participation confirmée")
      expect(rdv.reload.users.count).to eq(1)
      expect_notifications_sent_for(rdv, logged_user, :rdv_created)
      expect_webhooks_for(logged_user)
    end

    it "with an invited user (Token), redirect to rdv with invitaiton_token refreshed" do
      motif.update!(bookable_by: "agents_and_prescripteurs_and_invited_users")
      params.merge!(invitation_token: invitation_token)
      visit prendre_rdv_path(params)

      select_motif
      select_lieu
      expect_confirm_participation.to change { rdv.reload.users.count }.from(0).to(1)

      expect(page).not_to have_content("modifier") # can_change_participants?

      expect_notifications_sent_for(rdv, invited_user, :rdv_created)
      expect_webhooks_for(invited_user)
    end
  end

  context "Specific cases" do
    context "Invited User" do
      let(:user) { invited_user }
      let!(:motif) { create(:motif, :collectif, bookable_by: "agents_and_prescripteurs_and_invited_users", organisation: organisation, service: service) }

      it "do not display revoked or full rdvs for reservation (invitation error)" do
        params.merge!(invitation_token: invitation_token)
        visit root_path(params)

        rdv.status = "revoked"
        rdv.save
        select_motif
        expect(page).to have_content("Malheureusement, aucun créneau correspondant à votre invitation n'a été trouvé.")
        expect(page).to have_content("Toutes nos excuses pour cela.")

        rdv2.max_participants_count = 2
        create(:participation, rdv: rdv2)
        create(:participation, rdv: rdv2)
        rdv2.save
        visit root_path(params)
        expect(page).to have_content("Malheureusement, aucun créneau correspondant à votre invitation n'a été trouvé.")
        expect(page).to have_content("Toutes nos excuses pour cela.")
      end

      it "correctly display message of participation already existing" do
        params.merge!(invitation_token: invitation_token)
        create(:participation, rdv: rdv, user: user)
        visit root_path(params)
        select_motif
        select_lieu
        expect(page).to have_content("Vous êtes déjà inscrit pour cet atelier")
      end

      it "change existing excused participation for re registering process and display confirmation message" do
        params.merge!(invitation_token: invitation_token)
        create(:participation, rdv: rdv, user: user, status: "excused")

        visit root_path(params)
        select_motif
        select_lieu
        expect_confirm_participation.not_to change { rdv.reload.users.count }

        expect_notifications_sent_for(rdv, user, :rdv_created)
        expect_webhooks_for(user)
      end

      it "display rdv with cancelled tag when participation is excused or rdv is revoked", js: true do
        params.merge!(invitation_token: invitation_token)
        visit root_path(params)

        create(:participation, rdv: rdv, user: user, status: "excused")

        visit users_rdv_path(rdv, invitation_token: rdv.participation_token(user.id))
        fill_in(:letter0, with: "I")
        fill_in(:letter1, with: "N")
        fill_in(:letter2, with: "V")

        expect(page).to have_content("Annulé")
        create(:participation, rdv: rdv2, user: user, status: "revoked")
        rdv2.status = "revoked"
        rdv2.save

        visit users_rdv_path(rdv2, invitation_token: rdv2.participation_token(user.id))
        expect(page).to have_content("Annulé")
      end

      it "doesnt send notifications email to user if notif is unchecked" do
        params.merge!(invitation_token: invitation_token)
        visit root_path(params)
        select_motif
        select_lieu
        expect_confirm_participation(notif: false).to change { rdv.reload.users.count }.from(0).to(1)

        expect_notifications_sent_for(rdv, agent, :rdv_created)
        expect_no_notifications_for(rdv, user, :rdv_created)
      end

      it "can cancel collective rdv participation, with mail notifications only", js: true do
        params.merge!(invitation_token: invitation_token)
        visit root_path(params)

        participation = create(:participation, rdv: rdv, user: user, status: "unknown")

        stub_request(:post, "https://example.com/")

        visit users_rdv_path(rdv, invitation_token: rdv.participation_token(user.id))
        fill_in(:letter0, with: "I")
        fill_in(:letter1, with: "N")
        fill_in(:letter2, with: "V")

        expect_cancel_participation.to change { participation.reload.status }.from("unknown").to("excused")
        expect(rdv.reload.status).to eq("unknown")

        expect_notifications_sent_for(rdv, agent, :rdv_cancelled)
        # Mail notif only, SMS are not sent when cancellation is made by the user
        expect_notifications_sent_for(rdv, user, :rdv_cancelled, :mail)
        expect_webhooks_for(user)
      end

      it "can cancel collective rdv participation, without notifications", js: true do
        params.merge!(invitation_token: invitation_token)
        visit root_path(params)

        participation = create(:participation, rdv: rdv, user: user, status: "unknown")
        participation.send_lifecycle_notifications = false
        participation.save

        stub_request(:post, "https://example.com/")

        visit users_rdv_path(rdv, invitation_token: rdv.participation_token(user.id))
        fill_in(:letter0, with: "I")
        fill_in(:letter1, with: "N")
        fill_in(:letter2, with: "V")

        expect_cancel_participation.to change { participation.reload.status }.from("unknown").to("excused")
        expect(rdv.reload.status).to eq("unknown")

        expect_notifications_sent_for(rdv, agent, :rdv_cancelled)
        expect_no_notifications_for(rdv, user, :rdv_cancelled)
        expect_webhooks_for(user)
      end

      it "works with other participants (and do not notify others users)" do
        create(:participation, rdv: rdv, user: other_user1, status: "excused")
        create(:participation, rdv: rdv, user: other_user2, status: "unknown")

        params.merge!(invitation_token: invitation_token)

        visit root_path(params)
        select_motif
        select_lieu
        expect_confirm_participation.to change { rdv.reload.users.count }.from(2).to(3)
        expect(rdv.users_count).to eq(2) # users_count doesnt count other_user1 excused participation

        expect_notifications_sent_for(rdv, agent, :rdv_created)
        expect_notifications_sent_for(rdv, user, :rdv_created)
        expect_no_notifications_for(rdv, other_user1, :rdv_created)
        expect_no_notifications_for(rdv, other_user2, :rdv_created)
        expect_webhooks_for(user)
      end
    end

    context "Logged User" do
      let(:user) { logged_user }

      context "when other users sign up before we can finish booking" do
        it "redirects to creneau search" do
          login_as(user, scope: :user)
          visit root_path(params)
          select_motif
          select_lieu
          click_link("S'inscrire")
          click_button("Continuer")

          rdv.update!(max_participants_count: 2)
          create(:participation, rdv: rdv)
          create(:participation, rdv: rdv)

          click_button("Continuer")
          expect(page).to have_content("Ce créneau n'est plus disponible")
        end
      end

      it "do not display revoked or full rdvs for reservation (not available in this territory)" do
        login_as(user, scope: :user)
        visit root_path(params)

        rdv.status = "revoked"
        rdv.save
        select_motif
        expect(page).to have_content("Malheureusement, aucun créneau correspondant à votre recherche n'a été trouvé.")

        rdv2.max_participants_count = 2
        create(:participation, rdv: rdv2)
        create(:participation, rdv: rdv2)
        rdv2.save
        visit root_path(params)
        expect(page).to have_content("Malheureusement, aucun créneau correspondant à votre recherche n'a été trouvé.")
      end

      it "correctly display message of participation already existing" do
        login_as(user, scope: :user)

        create(:participation, rdv: rdv, user: user)
        visit root_path(params)
        select_motif
        select_lieu
        expect(page).to have_content("Vous êtes déjà inscrit pour cet atelier")
      end

      it "change existing excused participation for re registering process and display confirmation message" do
        login_as(user, scope: :user)

        create(:participation, rdv: rdv, user: user, status: "excused")

        visit root_path(params)
        select_motif
        select_lieu
        expect_confirm_participation.not_to change { rdv.reload.users.count }

        expect_notifications_sent_for(rdv, agent, :rdv_created)
        expect_notifications_sent_for(rdv, user, :rdv_created)
        expect_webhooks_for(user)
      end

      it "display rdv with cancelled tag when participation is excused or rdv is revoked" do
        login_as(user, scope: :user)
        visit root_path(params)

        create(:participation, rdv: rdv, user: user, status: "excused")

        visit users_rdv_path(rdv)

        expect(page).to have_content("Annulé")
        create(:participation, rdv: rdv2, user: user, status: "revoked")
        rdv2.status = "revoked"
        rdv2.save

        visit users_rdv_path(rdv2)
        expect(page).to have_content("Annulé")
      end

      it "doesnt send notifications email to user if notif is unchecked" do
        login_as(user, scope: :user)
        visit root_path(params)
        select_motif
        select_lieu
        expect_confirm_participation(notif: false).to change { rdv.reload.users.count }.from(0).to(1)

        expect_notifications_sent_for(rdv, agent, :rdv_created)
        expect_no_notifications_for(rdv, user, :rdv_created)
      end

      it "can cancel collective rdv participation, with mail notifications only" do
        login_as(user, scope: :user)
        visit root_path(params)

        participation = create(:participation, rdv: rdv, user: user, status: "unknown")

        stub_request(:post, "https://example.com/")

        visit users_rdv_path(rdv)

        expect_cancel_participation.to change { participation.reload.status }.from("unknown").to("excused")

        expect_notifications_sent_for(rdv, agent, :rdv_cancelled)
        # Mail notif only, SMS are not sent when cancellation is made by the user
        expect_notifications_sent_for(rdv, user, :rdv_cancelled, :mail)
        expect_webhooks_for(user)
      end

      it "can cancel collective rdv participation, without notifications" do
        login_as(user, scope: :user)
        visit root_path(params)

        participation = create(:participation, rdv: rdv, user: user, status: "unknown")
        participation.send_lifecycle_notifications = false
        participation.save

        stub_request(:post, "https://example.com/")

        visit users_rdv_path(rdv)

        expect_cancel_participation.to change { participation.reload.status }.from("unknown").to("excused")

        expect_notifications_sent_for(rdv, agent, :rdv_cancelled)
        expect_no_notifications_for(rdv, user, :rdv_cancelled)
        expect_webhooks_for(user)
      end

      it "works with other participants (and do not notify others users)" do
        create(:participation, rdv: rdv, user: other_user1, status: "excused")
        create(:participation, rdv: rdv, user: other_user2, status: "unknown")

        login_as(user, scope: :user)
        visit root_path(params)
        select_motif
        select_lieu
        expect_confirm_participation.to change { rdv.reload.users.count }.from(2).to(3)
        expect(rdv.users_count).to eq(2) # users_count doesnt count other_user1 excused participation

        expect_notifications_sent_for(rdv, agent, :rdv_created)
        expect_notifications_sent_for(rdv, user, :rdv_created)
        expect_no_notifications_for(rdv, other_user1, :rdv_created)
        expect_no_notifications_for(rdv, other_user2, :rdv_created)
        expect_webhooks_for(user)
      end
    end
  end
end
