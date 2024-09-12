class PlageOuvertureBlueprint < Blueprinter::Base
  identifier :id

  fields :ical_uid, :title, :first_day, :start_time, :end_time
  association :agent, blueprint: AgentBlueprint
  association :organisation, blueprint: OrganisationBlueprint
  association :lieu, blueprint: LieuBlueprint
  association :motifs, blueprint: MotifBlueprint

  field(:rrule) do |po|
    IcalFormatters::Rrule.from_recurrence(po.recurrence)
  end
  field(:ical) do |po|
    IcalFormatters::Ics.from_payload(po.payload).to_ical
  end
end
