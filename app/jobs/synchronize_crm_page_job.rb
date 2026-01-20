class SynchronizeCrmPageJob < ApplicationJob
  queue_as :default

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
