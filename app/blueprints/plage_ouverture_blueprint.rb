class PlageOuvertureBlueprint < Blueprinter::Base
  identifier :id

  fields :ical_uid, :title, :first_day, :start_time, :end_time
  association :agent, blueprint: AgentBlueprint
  association :organisation, blueprint: OrganisationBlueprint
  association :lieu, blueprint: LieuBlueprint
  association :motifs, blueprint: MotifBlueprint

  # rubocop:disable Style/SymbolProc
  field(:rrule) { _1.rrule }
  field(:ical) do |po|
    IcalHelpers::Ics.from_payload(po.payload).to_ical
  end
  # rubocop:enable Style/SymbolProc
end
