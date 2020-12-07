module AgentRdvWizard
  # cf https://medium.com/@nicolasblanco/developing-a-wizard-or-multi-steps-forms-in-rails-d2f3b7c692ce

  STEPS = ["step1", "step2", "step3"].freeze

  class Base
    include ActiveModel::Model

    attr_accessor :rdv, :service_id

    # delegates all getters and setters to rdv
    delegate(*::Rdv.attribute_names, to: :rdv)
    delegate :motif, :organisation, :agents, :users, to: :rdv

    def initialize(agent, organisation, attributes)
      rdv_attributes = attributes.to_h.symbolize_keys.except(:service_id)
      rdv_defaults = {
        agent_ids: [agent.id],
        organisation_id: organisation.id,
        starts_at: Time.zone.now,
      }
      @rdv = ::Rdv.new(rdv_defaults.merge(rdv_attributes))
      @rdv.duration_in_min ||= @rdv.motif.default_duration_in_min if @rdv.motif.present?
      @service_id = attributes.to_h.symbolize_keys[:service_id]
    end

    def to_query
      {
        motif_id: rdv.motif&.id,
        lieu_id: rdv.lieu_id,
        duration_in_min: rdv.duration_in_min,
        starts_at: rdv.starts_at&.to_s,
        user_ids: rdv.users&.map(&:id),
        agent_ids: rdv.agents&.map(&:id),
        context: rdv.context,
        service_id: service_id
      }
    end
  end

  class Step1 < Base
    validates :motif, :organisation, presence: true
  end

  class Step2 < Step1
    validates :users, presence: true
  end

  class Step3 < Step2; end
end
