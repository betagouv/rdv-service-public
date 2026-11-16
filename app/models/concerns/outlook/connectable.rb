module Outlook
  module Connectable
    extend ActiveSupport::Concern

    def connected_to_outlook?
      outlook_config&.microsoft_graph_token || false
    end

    # En cas d'erreur "invalid_grant", le refresh token est définitivement invalide.
    # L'erreur est fatale, inutile de retenter : on supprime la config Outlook et on prévient l'agent.
    def handle_invalid_grant(invalid_grant_error)
      if reload.outlook_config # On se sert de `outlook_config` comme sémaphore pour éviter une race condition.
        outlook_config.destroy!
        Agents::OutlookSyncMailer.with(agent:, error_description: invalid_grant_error.error_description).sync_disabled.deliver_later
        Sentry.capture_exception(invalid_grant_error, extra: { error_description: invalid_grant_error.error_description })
      end
    end

    included do
      has_one :outlook_config, dependent: :destroy

      scope :connected_to_outlook, -> { joins(:outlook_config).where.not(outlook_configs: { microsoft_graph_token: nil }) }
    end
  end
end
