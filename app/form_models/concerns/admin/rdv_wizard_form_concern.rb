# frozen_string_literal: true

module Admin::RdvWizardFormConcern
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Model
    include Rails.application.routes.url_helpers

    attr_accessor :rdv, :service_id
    attr_reader :agent_author

    # delegates all getters and setters to rdv
    delegate(*%i[id starts_at organisation_id created_at updated_at cancelled_at motif_id sequence
                 uuid old_location created_by context lieu_id status ends_at max_participants_count
                 rdv_collectif_users_count], to: :rdv)
    delegate :duration_in_min, to: :rdv
    delegate :motif, :organisation, :agents, :users, to: :rdv

    delegate :errors, to: :rdv
    delegate :ignore_benign_errors, :ignore_benign_errors=, :add_benign_error, :benign_errors, :not_benign_errors, :errors_are_all_benign?, to: :rdv

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
      @rdv.rdvs_users.each(&:set_default_notifications_flags)
      @service_id = attributes.to_h.symbolize_keys[:service_id]
    end
  end

  def to_query
    {
      motif_id: rdv.motif&.id,
      lieu_id: rdv.lieu_id,
      duration_in_min: rdv.duration_in_min,
      starts_at: rdv.starts_at&.to_s,
      user_ids: rdv.rdvs_users&.map(&:user_id),
      agent_ids: rdv.agents&.map(&:id),
      context: rdv.context,
      service_id: service_id
    }
  end

  def step_number
    self.class.name[-1].to_i
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
