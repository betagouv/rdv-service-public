# frozen_string_literal: true

module Outlook
  module Connectable
    extend ActiveSupport::Concern

    included do
      scope :connected_to_outlook, -> { where.not(microsoft_graph_token: nil) }

      alias_attribute :connected_to_outlook?, :microsoft_graph_token?

      encrypts :microsoft_graph_token
      encrypts :refresh_microsoft_graph_token
    end

    def refresh_outlook_token
      refresh_token_try = Outlook::User.new(agent: self).refresh_token
      if refresh_token_try["error"].present?
        Sentry.capture_message("Error refreshing Microsoft Graph Token for #{email}: #{refresh_token_try['error_description']}")
      elsif refresh_token_try["access_token"].present?
        update(microsoft_graph_token: refresh_token_try["access_token"])
      end
    end
  end
end
