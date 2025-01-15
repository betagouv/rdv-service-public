class CronJob::CrmSync < ApplicationJob
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
        rdv_count = Rdv.where(organisation: organisations_ids(notion_page.properties["COMPTE PROD"].url)).count
        client.update_page(page_id: notion_page.id, properties: { "NOMBRE DE RDV" => rdv_count })
      end
    end
  end

  private

  def organisations_ids(account_url)
    if account_url.match('territories/(\d+)')
      territory_id = account_url.match('territories/(\d+)')[1]
      territory = Territory.find(territory_id)
      Organisation.where(territory: territory).pluck(:id)
    elsif account_url.match('organisations/(\d+)')
      [account_url.match('organisations/(\d+)')[1]]
    else
      raise "Unrecognized account URL: #{account_url}"
    end
  end

  def instance_hostname
    ENV["HOST"].sub("https://", "")
  end

  def client
    @client ||= Notion::Client.new(token: ENV["NOTION_API_SECRET"])
  end
end
