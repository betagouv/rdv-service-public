module RdvWizard
  # cf https://medium.com/@nicolasblanco/developing-a-wizard-or-multi-steps-forms-in-rails-d2f3b7c692ce

  STEPS = ["step1", "step2", "step3"].freeze

  class Base
    include ActiveModel::Model

    attr_accessor :rdv, :plage_ouverture_location

    # delegates all getters and setters to rdv
    delegate(*::Rdv.attribute_names, to: :rdv)
    delegate :motif, :organisation, :agents, to: :rdv

    def initialize(agent, organisation, attributes)
      @plage_ouverture_location = attributes[:plage_ouverture_location]
      rdv_attributes = attributes.to_h.symbolize_keys.reject { |k, _v| k == :plage_ouverture_location }
      rdv_defaults = {
        agent_ids: [agent.id],
        organisation_id: organisation.id,
        starts_at: Time.zone.now,
      }
      @rdv = ::Rdv.new(rdv_defaults.merge(rdv_attributes))
      @rdv.duration_in_min ||= @rdv.motif.default_duration_in_min if @rdv.motif.present?
      @rdv.location ||= @plage_ouverture_location if @rdv.motif&.public_office?
    end

    def to_query
      rdv.to_query.merge(plage_ouverture_location: plage_ouverture_location)
    end
  end

  class Step1 < Base
    validates :motif, :organisation, presence: true
  end

  class Step2 < Step1
    validates :duration_in_min, :starts_at, :agents, presence: true
  end

  class Step3 < Step2; end
end
