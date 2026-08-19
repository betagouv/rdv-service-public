RSpec.describe "Les admins de territoire peuvent gérer le travail pour les jours fériés et les dimanches" do
  let!(:territory) { create(:territory) }
  let!(:agent) { create(:agent, role_in_territories: [territory]) }

  specify do
    login_as(agent, scope: :agent)
    visit edit_admin_territory_calendar_settings_path(territory)

    check "Autoriser les rendez-vous le dimanche et les jours fériés"
    expect { click_on "Enregistrer" }.to change { territory.reload.work_on_sunday }.from(false).to(true)

    uncheck "Autoriser les rendez-vous le dimanche et les jours fériés"
    expect { click_on "Enregistrer" }.to change { territory.reload.work_on_sunday }.from(true).to(false)
  end
end
