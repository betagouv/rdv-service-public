module ZammadCustomer
  class Attributes
    include ActiveModel::Model
    include ActiveModel::Attributes

    %i[email firstname lastname phone super_admin_url note rdvsp_role].each do |att|
      attribute att, :string
    end

    attribute :instance, :string, default: Domain.default_domain_for_current_instance.to_s

    def augment_with(augmenter)
      augmenter.augment(self)
    end

    # point d’entrée générique : on ne sait pas si c’est un ticket agent ou usager
    def find_user_or_agent_and_augment
      agent_matcher = Matchers::AgentMatcher.new(self)
      agent_matcher.find_record
      if agent_matcher.matched?
        augment_with(Augmenters::AgentAugmenter.new(agent_matcher.record)) if agent_matcher.record.present?
        self.note = agent_matcher.details
        return
      end
      user_matcher = Matchers::UserMatcher.new(self)
      user_matcher.find_record
      if user_matcher.matched?
        augment_with(Augmenters::UserAugmenter.new(user_matcher.record)) if user_matcher.record.present?
        self.note = user_matcher.details
      else
        self.note = "Aucun usager ni agent trouvé"
      end
    end

    def to_h = attributes
  end
end
