module ZammadCustomer
  module Augmenters
    class AgentAugmenter
      include Rails.application.routes.url_helpers
      def initialize(agent)
        @agent = agent
      end

      def augment(customer_attributes)
        customer_attributes.super_admin_url = super_admins_agent_url(id: @agent.id, host: Domain.default_domain_for_current_instance.host_name)
        customer_attributes.rdvsp_role = "agent"
      end
    end

    class UserAugmenter
      include Rails.application.routes.url_helpers
      def initialize(user)
        @user = user
      end

      def augment(customer_attributes)
        customer_attributes.super_admin_url = super_admins_user_url(id: @user.id, host: Domain.default_domain_for_current_instance.host_name)
        customer_attributes.rdvsp_role = "user"
      end
    end
  end
end
