class CronJob::SendMattermostNotificationsForZammadTicketsJob < CronJob
  include  ActionView::Helpers::DateHelper

  queue_as :latency_5m
  attr_reader :new_and_open_tickets, :tickets_counts_by_owner

  def perform
    return if Rails.env.production? && # on veut pouvoir exécuter ce job en dev
              ENV["HOST"] != "https://rdv.anct.gouv.fr" # en prod on ne veut pas l’éxécuter sur chaque app scalingo

    Rails.logger.debug "Fetching data from Zammad…"
    @new_and_open_tickets = ZammadApiClient.search_new_and_open_tickets
    @tickets_counts_by_owner = new_and_open_tickets.map(&:owner).tally
    Rails.logger.debug { "Done fetching data from Zammad. Got #{new_and_open_tickets.count} new and open tickets" }

    Rails.logger.debug "Building message…"
    message = build_message
    Rails.logger.debug "Done building message."

    Rails.logger.debug "Sending message to Mattermost channel"
    MattermostApiClient.send_message(
      channel: "allo-vigie", # le nom de chaine est paramétrisé, les emojis disparaissent
      text: message,
      username: "Zammad",
      icon_url: "https://raw.githubusercontent.com/zammad/zammad/refs/heads/develop/public/assets/images/logo.svg"
    )
    Rails.logger.debug "Done sending message to Mattermost."
  end

  private

  def build_message
    agent_emails = tickets_counts_by_owner.keys.sort.map do |agent_email|
      agent_email == "-" ? " non assignés" : agent_email.split("@").first.split(".").first
    end
    ticket_counts = tickets_counts_by_owner.keys.sort.map do |owner|
      count = tickets_counts_by_owner[owner]
      "#{count}&nbsp;ticket#{'s' if count > 1}"
    end
    <<~MSG
      | #{agent_emails.join(' | ')} |
      | - | - |
      | #{ticket_counts.join(' | ')} |

      Au total **#{new_and_open_tickets.count} tickets** attendent une réponse.

      Le plus ancien attend une réponse depuis **#{time_ago_in_words(new_and_open_tickets.map(&:awaiting_response_since).min)}**

      - [Voir les #{new_and_open_tickets.count} tickets en attente de réponse](https://zammad10.ethibox.fr/#ticket/view/all_open)
      - [Voir mes tickets en attente de réponse](https://zammad10.ethibox.fr/#ticket/view/my_assigned)
    MSG
  end
end
