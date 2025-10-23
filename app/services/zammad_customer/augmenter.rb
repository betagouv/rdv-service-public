module ZammadCustomer
  class Augmenter
    # point d’entrée générique : on ne sait pas si c’est un ticket agent ou usager
    include Rails.application.routes.url_helpers

    attr_reader :zammad_customer

    delegate :email, :phone, to: :zammad_customer

    def initialize(zammad_customer)
      @zammad_customer = zammad_customer
    end

    # rubocop:disable Lint/AssignmentInCondition
    def run
      user_matcher = Matchers::UserMatcher.new(zammad_customer)
      if agent = Agent.find_by(email:)
        augment_with_agent(agent)
        zammad_customer.note = "Agent trouvé avec l'email #{email}"
      elsif user_matcher.find_user
        augment_with_user(user_matcher.user)
        zammad_customer.note = user_matcher.details
      elsif user_matcher.multiple_matches
        zammad_customer.note = user_matcher.details
      else
        zammad_customer.note = "Aucun usager ni agent trouvé"
      end
    end
    # rubocop:enable Lint/AssignmentInCondition

    def host = ::Domain.default_domain_for_current_instance.host_name

    def augment_with_agent(agent)
      zammad_customer.super_admin_url = super_admins_agent_url(id: agent.id, host:)
      zammad_customer.rdvsp_role = "agent"
    end

    def augment_with_user(user)
      zammad_customer.super_admin_url = super_admins_user_url(id: user.id, host:)
      zammad_customer.rdvsp_role = "user"
    end
  end
end
