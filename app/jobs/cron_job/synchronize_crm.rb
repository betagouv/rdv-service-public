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

    jobs = []
    client.database_query(database_id: NOTION_DATABASE_ID, filter:) do |page|
      page.results.each do |notion_page|
        jobs << sync_job_for(notion_page)
      end
    end

    # Notion rate-limiting is 3 API calls per second, so we'll execute jobs every 400ms
    delay = 0.seconds
    jobs.each do |job|
      job.set(wait: delay)
      delay += 0.4.seconds
    end

    ActiveJob.perform_all_later(jobs)
  end

  private

  def sync_job_for(notion_page)
    SynchronizeCrmPageJob.new(
      notion_page_id: notion_page.id,
      account_url: notion_page.properties["COMPTE PROD"].url,
      notion_page_url: notion_page.url,
      notion_page_title: notion_page.properties["Project name"]["title"][0]["plain_text"]
    )
  end

  def instance_hostname
    ENV["HOST"]
  end

  def client
    @client ||= Notion::Client.new(token: ENV["NOTION_API_SECRET"])
  end
end
