module Outlook
  module Connectable
    extend ActiveSupport::Concern

    def connected_to_outlook?
      microsoft_graph_token.present?
    end

    included do
      scope :connected_to_outlook, -> { where.not(microsoft_graph_token: nil) }

      encrypts :microsoft_graph_token
      encrypts :refresh_microsoft_graph_token
    end
  end
end
