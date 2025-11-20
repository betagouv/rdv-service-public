class CronJob::SynchronizeCrm < CronJob
  # Base de données "Activation"
  # ID récupéré dans l’URL de la page
  # Cf: https://developers.notion.com/reference/retrieve-a-database
  NOTION_DATABASE_ID = ENV["NOTION_DATABASE_ID"].freeze

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
        ids = organisations_ids(notion_page)
        rdv_count = ids.blank? ? nil : Rdv.where(organisation: ids).count
        last_rdv = Rdv.where(organisation: ids).order(created_at: :desc).first
        if last_rdv
          client.update_page(page_id: notion_page.id, properties: { "NOMBRE DE RDV" => rdv_count, "DATE CREATION DERNIER RDV" => { start: last_rdv.created_at&.strftime("%Y-%m-%d") } })
        else
          client.update_page(page_id: notion_page.id, properties: { "NOMBRE DE RDV" => rdv_count, "DATE CREATION DERNIER RDV" => nil })
        end
      end
    end
  end

  private

  # Prend une URL de compte au format '/organisations/1' ou '/territories/1' et retourne les IDs des organisations correspondantes
  # On ne retourne les IDs que si les organisations existent dans la base de données
  def organisations_ids(notion_page)
    account_url = notion_page.properties["COMPTE PROD"].url
    if account_url.match('territories/(\d+)')
      territory_id = account_url.match('territories/(\d+)')[1]
      territory = Territory.find_by(id: territory_id)
      Organisation.where(territory: territory).pluck(:id)
    elsif account_url.match('organisations/(\d+)')
      Organisation.where(id: account_url.match('organisations/(\d+)')[1]).pluck(:id)
    else
      MattermostApiClient.send_message(
        channel: "startup-rdv-alertes-crm",
        text: "L’URL du compte PROD de la carte Notion [#{notion_page.properties['Project name']['title'][0]['plain_text']}](#{notion_page.url}), est incorrecte.",
        username: "CRM",
        icon_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Notion-logo.svg/100px-Notion-logo.svg.png"
      )
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
