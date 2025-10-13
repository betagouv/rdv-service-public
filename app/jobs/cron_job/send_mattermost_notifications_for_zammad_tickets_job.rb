class CronJob::SendMattermostNotificationsForZammadTicketsJob < CronJob
  include  ActionView::Helpers::DateHelper
  queue_as :latency_5m

  def perform
    Rails.logger.debug "Fetching data from Zammad…"
    unassigned_tickets = ZammadApiClient.search_unassigned_tickets
    assigned_tickets = ZammadApiClient.search_assigned_tickets
    assigned_tickets_counts_by_agent_email = assigned_tickets.map(&:owner).tally
    Rails.logger.debug { "Done fetching data from Zammad. Got #{unassigned_tickets.count} unassigned tickets and #{assigned_tickets.count} assigned tickets." }

    Rails.logger.debug "Building message…"
    agent_emails = assigned_tickets_counts_by_agent_email.keys.sort.map do |agent_email|
      agent_email == "-" ? "N/A" : agent_email.split("@").first.split(".").first
    end
    ticket_counts = assigned_tickets_counts_by_agent_email.keys.sort.map { "#{assigned_tickets_counts_by_agent_email[_1]}&nbsp;ticket(s)" }
    message = <<~MSG
      #{unassigned_tickets.count} tickets non-assignés en attente de réponse. Le plus ancien attend une réponse depuis #{time_ago_in_words(unassigned_tickets.map(&:awaiting_response_since).min)} [Voir ces #{unassigned_tickets.count} tickets](https://zammad10.ethibox.fr/#ticket/view/all_unassigned)

      #{assigned_tickets.count} tickets assignés en attente de réponse. Le plus ancien attend depuis #{time_ago_in_words(assigned_tickets.map(&:awaiting_response_since).min)}.

      | #{agent_emails.join(' | ')} |
      | - | - |
      | #{ticket_counts.join(' | ')} |

      [Voir les tickets qui vous sont assignés](https://zammad10.ethibox.fr/#ticket/view/my_assigned)
    MSG
    Rails.logger.debug "Done building message."

    Rails.logger.debug "Sending message to Mattermost channel"
    MattermostApiClient.send_message(
      channel: "startup-rdv-service-public-dev-notifs",
      text: message,
      username: "Zammad",
      icon_url: "https://raw.githubusercontent.com/zammad/zammad/refs/heads/develop/public/assets/images/logo.svg"
    )
    Rails.logger.debug "Done sending message to Mattermost."
  end
end
