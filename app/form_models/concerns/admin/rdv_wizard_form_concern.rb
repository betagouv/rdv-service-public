module Admin::RdvWizardFormConcern
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Model
    include Rails.application.routes.url_helpers

    attr_accessor :rdv, :service_id
    attr_reader :agent_author

    # delegates all getters and setters to rdv
    delegate(*::Rdv.attribute_names, to: :rdv)
    delegate :motif, :organisation, :agents, :users, to: :rdv

    def initialize(agent_author, organisation, attributes)
      rdv_attributes = attributes.to_h.symbolize_keys.except(:service_id)
      rdv_defaults = {
        agent_ids: [agent_author.id],
        organisation_id: organisation.id,
        starts_at: Time.zone.now
      }
      @organisation = organisation
      @agent_author = agent_author
      @rdv = ::Rdv.new(rdv_defaults.merge(rdv_attributes))
      @rdv.duration_in_min ||= @rdv.motif.default_duration_in_min if @rdv.motif.present?
      @service_id = attributes.to_h.symbolize_keys[:service_id]
      @active_warnings_confirm_decision = attributes.to_h.symbolize_keys[:active_warnings_confirm_decision]
    end
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

  def step_number
    self.class.name[-1].to_i
  end

  def i18n_scope
    "admin_rdv_wizard_form.step#{step_number}"
  end

  def save
    valid?
  end

  def success_flash
    {}
  end

  def previous_step_path
    if step_number <= 1
      admin_organisation_agent_agenda_path(organisation, agent_author)
    else
      path_for_step(step_number - 1)
    end
  end

  def path_for_step(target_step_number)
    new_admin_organisation_rdv_wizard_step_path(organisation, to_query.merge(step: target_step_number))
  end
end
