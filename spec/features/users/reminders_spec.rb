RSpec.describe "Les usagers peuvent voir les détails de leurs rendez-vous depuis les sms de rappel" do
  let!(:rdv) { create(:rdv, starts_at: 2.days.from_now, users: [user]) }
  let(:user) { create(:user, last_name: "Factice") }

  before { stub_netsize_ok }

  it "marche même si on envoie plusieurs notifications" do
    travel_to(1.hour.ago)
    Notifiers::RdvUpcomingReminder.perform_with(rdv, nil)
    perform_enqueued_jobs

    link_in_first_sms = Receipt.last.content[/www\..*/] # On ne met pas le 'https://' dans le lien, donc le www est une bonne regex pour retrouver le lien
    path_in_first_sms = link_in_first_sms.gsub(Domain::RDV_SOLIDARITES.host_name, "")
    visit path_in_first_sms
    fill_in(:letter0, with: "F")
    fill_in(:letter1, with: "A")
    fill_in(:letter2, with: "C")
    click_on("OK")

    expect(page).to have_content "Votre RDV"

    travel_back # Pour expirer les cookies
    # On envoie une deuxième notification
    Notifiers::RdvUpcomingReminder.perform_with(rdv.reload, nil)
    perform_enqueued_jobs

    link_in_second_sms = Receipt.last.content[/www\..*/] # On ne met pas le 'https://' dans le lien, donc le www est une bonne regex pour retrouver le lien
    path_in_second_sms = link_in_second_sms.gsub(Domain::RDV_SOLIDARITES.host_name, "")
    visit path_in_second_sms
    fill_in(:letter0, with: "F")
    fill_in(:letter1, with: "A")
    fill_in(:letter2, with: "C")
    click_on("OK")

    expect(page).to have_content "Votre RDV"

    visit path_in_first_sms

    expect(page).not_to have_content "Votre invitation n'est pas valide."

    expect(page).to have_content "Votre RDV"
  end
end
