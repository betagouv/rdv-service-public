class CreateCrmPageJob < ApplicationJob
  queue_as :default

  # Base de données "Activation"
  # ID récupéré dans l’URL de la page
  # Cf: https://developers.notion.com/reference/retrieve-a-database
  NOTION_DATABASE_ID = ENV["NOTION_DATABASE_ID"].freeze

  def perform(territory_id)
    return unless ENV["NOTION_API_SECRET"]

    territory = Territory.find(territory_id)
    client.create_page(
      parent: {
        type: "database_id",
        database_id: NOTION_DATABASE_ID,
      },
      properties: {
        "Project name": {
          title: [
            {
              text: {
                content: territory.name_in_stats,
              },
            },
          ],
        },
        STATUS: {
          status: {
            name: "ACTIVATION",
          },
        },
        CATEGORIE: {
          multi_select: [
            { name: territory.category },
          ],
        },
        ENTREE: {
          select: {
            name: OauthApplication.agent_is_verified_by_an_application?(territory.admin_agents.first) ? "Intégration" : "Self-Onboarding",
          },
        },
        "COMPTE PROD": {
          url: "#{ENV['HOST']}/super_admins/territories/#{territory.id}",
        },
        CONTACT: {
          email: territory.admin_agents.count == 1 ? territory.admin_agents.first.email : nil,
        },
      }
    )
  end

  private

  def client
    @client ||= Notion::Client.new(token: ENV["NOTION_API_SECRET"])
  end
end
