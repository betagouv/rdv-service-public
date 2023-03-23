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
  end
end
