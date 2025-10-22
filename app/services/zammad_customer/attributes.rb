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

    def find_user_or_agent_and_augment
      # point d’entrée générique : on ne sait pas si c’est un ticket agent ou usager
      match_details = nil
      [
        [Matchers::UserMatcher, Augmenters::UserAugmenter],
        [Matchers::AgentMatcher, Augmenters::AgentAugmenter],
      ].each do |matcher_class, augmenter_class|
        matcher = matcher_class.new(self)
        matcher.find_record
        next unless matcher.matched?

        augment_with(augmenter_class.new(matcher.record)) if matcher.record.present?
        match_details = matcher.details
        break
      end
      self.note = match_details || "Aucun usager ni agent trouvé"
    end

    def to_h = attributes
  end
end
