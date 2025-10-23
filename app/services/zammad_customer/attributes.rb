module ZammadCustomer
  class Attributes
    include Rails.application.routes.url_helpers
    include ActiveModel::Model # provides the convenient initializer
    include ActiveModel::Attributes # lets us declare attributes easily

    %i[email firstname lastname phone super_admin_url note rdvsp_role].each do |att|
      attribute att, :string
    end

    attribute :instance, :string, default: Domain.default_domain_for_current_instance.to_s

    def augment_with(augmenter) = augmenter.augment(self)
    def to_h = attributes

    # point d’entrée générique : on ne sait pas si c’est un ticket agent ou usager
    # rubocop:disable Lint/AssignmentInCondition
    def find_user_or_agent_and_augment
      user_matcher = Matchers::UserMatcher.new(self)
      if agent = Agent.find_by(email:)
        augment_with_agent(agent)
        self.note = "Agent trouvé avec l'email #{email}"
      elsif user_matcher.find_user
        augment_with_user(user_matcher.user)
        self.note = user_matcher.details
      elsif user_matcher.multiple_matches
        self.note = user_matcher.details
      else
        self.note = "Aucun usager ni agent trouvé"
      end
    end
    # rubocop:enable Lint/AssignmentInCondition

    def augment_with_agent(agent)
      self.super_admin_url = super_admins_agent_url(id: agent.id, host: Domain.default_domain_for_current_instance.host_name)
      self.rdvsp_role = "agent"
    end

    def augment_with_user(user)
      self.super_admin_url = super_admins_user_url(id: user.id, host: Domain.default_domain_for_current_instance.host_name)
      self.rdvsp_role = "user"
    end
  end
end
