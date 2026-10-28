class SynchronizeCrmPageJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(perform_limit: 1) # NOTE: le rate limit 3 req/s est partagé avec le cron parent

  # Le 429 est transitoire : on attend 5 minutes entre chaque tentative,
  # sans épuiser les 13 tentatives du retry_on StandardError du DefaultJobBehaviour
  retry_on Notion::Api::Errors::TooManyRequests, wait: 5.minutes, attempts: 10, priority: DefaultJobBehaviour::PRIORITY_OF_RETRIES

  # Les erreurs Notion définitives ne méritent pas d'être retentées
  discard_on(Notion::Api::Errors::ObjectNotFound) { |_job, error| Sentry.capture_exception(error) }
  discard_on(Notion::Api::Errors::Unauthorized) { |_job, error| Sentry.capture_exception(error) }
  discard_on(Notion::Api::Errors::Forbidden) { |_job, error| Sentry.capture_exception(error) }

  queue_as :latency_whenever

  def perform(notion_page_id:, account_url:, notion_page_url:, notion_page_title:)
    return unless ENV["NOTION_API_SECRET"]

    ids = organisations_ids(account_url, notion_page_url, notion_page_title)
    return if ids.blank?

    territory = Organisation.find(ids.first).territory
    last_rdv = Rdv.where(organisation: ids).order(created_at: :desc).first
    properties = {
      "NOMBRE DE RDV" => Rdv.where(organisation: ids).count,
      "DATE CREATION DERNIER RDV" => last_rdv ? { start: last_rdv.created_at.strftime("%Y-%m-%d") } : nil,
      "DATE CREATION ESPACE" => { start: territory.created_at.strftime("%Y-%m-%d") },
      "NOMBRE AGENTS ACTIFS" => territory.organisations_agents.where("last_sign_in_at >= ?", 30.days.ago).count,
    }
    client.update_page(page_id: notion_page_id, properties:)
  end

  private

  def organisations_ids(account_url, notion_page_url, notion_page_title)
    if account_url.match('territories/(\d+)')
      territory_id = account_url.match('territories/(\d+)')[1]
      territory = Territory.find_by(id: territory_id)
      Organisation.where(territory: territory).pluck(:id)
    elsif account_url.match('organisations/(\d+)')
      Organisation.where(id: account_url.match('organisations/(\d+)')[1]).pluck(:id)
    else
      MattermostApiClient.send_message(
        channel: "startup-rdv-alertes-crm",
        text: "L'URL du compte PROD de la carte Notion [#{notion_page_title}](#{notion_page_url}), est incorrecte.",
        username: "CRM",
        icon_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Notion-logo.svg/100px-Notion-logo.svg.png"
      )
      []
    end
  end

  def client
    @client ||= Notion::Client.new(token: ENV["NOTION_API_SECRET"])
  end
end
