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
        SynchronizeCrmPageJob.perform_later(
          notion_page_id: notion_page.id,
          account_url: notion_page.properties["COMPTE PROD"].url,
          notion_page_url: notion_page.url,
          notion_page_title: notion_page.properties["Project name"]["title"][0]["plain_text"]
        )
      end
    end
  end

  private

  def instance_hostname
    ENV["HOST"]
  end

  def client
    @client ||= Notion::Client.new(token: ENV["NOTION_API_SECRET"])
  end
end
