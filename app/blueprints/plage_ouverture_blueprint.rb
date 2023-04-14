# frozen_string_literal: true

class PlageOuvertureBlueprint < Blueprinter::Base
  identifier :id

  fields :ical_uid, :title, :first_day, :start_time, :end_time
  association :agent, blueprint: AgentBlueprint
  association :organisation, blueprint: OrganisationBlueprint
  association :lieu, blueprint: LieuBlueprint
  association :motifs, blueprint: MotifBlueprint

  # rubocop:disable Style/SymbolProc
  field(:rrule) { _1.rrule }
  field(:ical) { _1.to_ical }
  # rubocop:enable Style/SymbolProc

  field(:web_url) do |plage|
    Rails.application.routes.url_helpers.admin_organisation_plage_ouverture_url(
      id: plage.id,
      organisation_id: plage.organisation.id,
      host: plage.domain.dns_domain_name
    )
  end
end
