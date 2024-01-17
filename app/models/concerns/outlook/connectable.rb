module Outlook
  module Connectable
    extend ActiveSupport::Concern

    included do
      scope :connected_to_outlook, -> { where.not(microsoft_graph_token: nil) }

      alias_attribute :connected_to_outlook?, :microsoft_graph_token?

      encrypts :microsoft_graph_token
      encrypts :refresh_microsoft_graph_token

      def outlook_domain_connected?
        return if email.blank?

        email_domain = email.split("@").last
        self.class.connected_to_outlook.where("email ILIKE ?", "%@#{email_domain}").any?
      end
    end
  end
end
