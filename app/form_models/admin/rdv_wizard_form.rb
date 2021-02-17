module Admin::RdvWizardForm
  # cf https://medium.com/@nicolasblanco/developing-a-wizard-or-multi-steps-forms-in-rails-d2f3b7c692ce

  STEPS = ["step1", "step2", "step3"].freeze

  class Base
    include ActiveModel::Model
    include Rails.application.routes.url_helpers

    attr_accessor :rdv, :service_id

    # delegates all getters and setters to rdv
    delegate(*::Rdv.attribute_names, to: :rdv)
    delegate :motif, :organisation, :agents, :users, to: :rdv

    def initialize(agent_author, organisation, attributes)
      rdv_attributes = attributes.to_h.symbolize_keys.except(:service_id)
      rdv_defaults = {
        agent_ids: [agent_author.id],
        organisation_id: organisation.id,
        starts_at: Time.zone.now,
      }
      @organisation = organisation
      @agent_author = agent_author
      @rdv = ::Rdv.new(rdv_defaults.merge(rdv_attributes))
      @rdv.duration_in_min ||= @rdv.motif.default_duration_in_min if @rdv.motif.present?
      @service_id = attributes.to_h.symbolize_keys[:service_id]
      @active_warnings_confirm_decision = attributes.to_h.symbolize_keys[:active_warnings_confirm_decision]
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

    def save
      valid?
    end

    def success_flash
      {}
    end
  end

  class Step1 < Base
    validates :motif, :organisation, presence: true

    def success_path
      new_admin_organisation_rdv_wizard_step_path(@organisation, step: 2, **to_query)
    end
  end

  class Step2 < Step1
    validates :users, presence: true
    validate :phone_number_present_for_motif_by_phone

    def phone_number_present_for_motif_by_phone
      errors.add(:base, I18n.t("activerecord.attributes.rdv.phone_number_missing")) if rdv.motif.phone? && users.all? { _1.phone_number.blank? }
    end

    def success_path
      new_admin_organisation_rdv_wizard_step_path(@organisation, step: 3, **to_query)
    end
  end

  class Step3 < Step2
    include Admin::RdvFormConcern

    def success_path
      admin_organisation_agent_path(
        rdv.organisation,
        agents.include?(@agent_author) ? @agent_author : agents.first,
        selected_event_id: rdv.id,
        date: starts_at.to_date
      )
    end

    def success_flash
      { notice: "Le rendez-vous a été créé." }
    end

    private

    def validate_rdv
      return unless rdv.valid?

      rdv.errors.each { errors.add(_1, _2) }
    end

    def warn_overlapping_plage_ouverture
      return true unless overlapping_plages_ouvertures?

      overlapping_plages_ouvertures
        .map { PlageOuverturePresenter.new(_1, agent_context) }
        .each { warnings.add(:base, _1.overlaps_rdv_error_message, active: true) }
    end

    def agent_context
      AgentContext.new(@agent_author, @organisation)
    end
  end
end
