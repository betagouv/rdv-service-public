module ZammadCustomer
  class Attributes
    include ActiveModel::Model
    include ActiveModel::Attributes

    %i[email firstname lastname phone super_admin_url note rdvsp_role].each do |att|
      attribute att, :string
    end

    attribute :instance, :string, default: Domain.default_domain_for_current_instance.to_s

    def augment_with(augmenter) = augmenter.augment(self)
    def to_h = attributes

    # point d’entrée générique : on ne sait pas si c’est un ticket agent ou usager
    def find_user_or_agent_and_augment
      agent_matcher = Matchers::AgentMatcher.new(self)
      user_matcher = Matchers::UserMatcher.new(self)
      if agent_matcher.find_agent
        augment_with(Augmenters::AgentAugmenter.new(agent_matcher.agent))
        self.note = agent_matcher.details
      elsif user_matcher.find_user
        augment_with(Augmenters::UserAugmenter.new(user_matcher.user))
        self.note = user_matcher.details
      elsif user_matcher.multiple_matches
        self.note = user_matcher.details
      else
        self.note = "Aucun usager ni agent trouvé"
      end
    end
  end
end
