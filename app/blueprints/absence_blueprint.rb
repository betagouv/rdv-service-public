# frozen_string_literal: true

class AbsenceBlueprint < Blueprinter::Base
  identifier :id

  fields :ical_uid, :title, :first_day, :end_day, :start_time, :end_time
  association :agent, blueprint: AgentBlueprint
  association :organisation, blueprint: OrganisationBlueprint

  # rubocop:disable Style/SymbolProc
  field(:rrule) { _1.rrule }
  field(:ical) { _1.to_ical }
  # rubocop:enable Style/SymbolProc

  field(:web_url) do |absence|
    Rails.application.routes.url_helpers.edit_admin_organisation_absence_url(
      id: absence.id,
      organisation_id: absence.organisation.id,
      host: absence.domain.dns_domain_name
    )
  end
end
