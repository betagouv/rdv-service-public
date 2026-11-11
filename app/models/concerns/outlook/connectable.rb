module Outlook
  module Connectable
    extend ActiveSupport::Concern

    def connected_to_outlook?
      outlook_config&.connected? || false
    end

    included do
      has_one :outlook_config, dependent: :destroy

      scope :connected_to_outlook, -> { joins(:outlook_config).where.not(outlook_configs: { microsoft_graph_token: nil }) }
    end
  end
end
