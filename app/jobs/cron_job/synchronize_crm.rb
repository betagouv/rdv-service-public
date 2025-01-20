class CronJob::SynchronizeCrm < ApplicationJob
  # Base de données "Activation"
  # ID récupéré dans l’URL de la page
  # Cf: https://developers.notion.com/reference/retrieve-a-database
  NOTION_DATABASE_ID = "81a35c7b2490464590a408bbbb78ca2e".freeze

  def perform
    return unless ENV["NOTION_API_SECRET"]

    filter = {
      and: [
        {
          property: "COMPTE PROD",
          url: {
            contains: instance_hostname,
          },
        },
      ],
    }

    client.database_query(database_id: NOTION_DATABASE_ID, filter:) do |page|
      page.results.each do |notion_page|
        ids = organisations_ids(notion_page.properties["COMPTE PROD"].url)
        if ids.blank?
          client.update_page(page_id: notion_page.id, properties: { "NOMBRE DE RDV" => nil })
        else
          rdv_count = Rdv.where(organisation: ids).count
          client.update_page(page_id: notion_page.id, properties: { "NOMBRE DE RDV" => rdv_count })
        end
      end
    end
  end

  private

  # Prends une URL de compte au format '/organisations/1' ou '/territories/1' et retourne les IDs des organisations correspondantes
  # On ne retourne les IDs que si les organisations existent dans la base de données
  def organisations_ids(account_url)
    if account_url.match('territories/(\d+)')
      territory_id = account_url.match('territories/(\d+)')[1]
      territory = Territory.find_by(id: territory_id)
      Organisation.where(territory: territory).pluck(:id)
    elsif account_url.match('organisations/(\d+)')
      Organisation.where(id: account_url.match('organisations/(\d+)')[1]).pluck(:id)
    else
      Sentry.capture_message("Unrecognized account URL: #{account_url}", fingerprint: ["CronJob::SynchronizeCrm"])
      []
    end
  end

  def instance_hostname
    ENV["HOST"]
  end

  def client
    @client ||= Notion::Client.new(token: ENV["NOTION_API_SECRET"])
  end
end
