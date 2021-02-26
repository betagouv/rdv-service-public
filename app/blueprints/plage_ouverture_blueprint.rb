class PlageOuvertureBlueprint < Blueprinter::Base
  identifier :id

  fields :ical_uid, :title, :first_day, :start_time, :end_time
  association :agent, blueprint: AgentBlueprint
  association :organisation, blueprint: OrganisationBlueprint
  association :lieu, blueprint: LieuBlueprint
  association :motifs, blueprint: MotifBlueprint

  field :rrule do |plage_ouverture|
    Ics.rrule(Ics.payload_for(plage_ouverture, :create))
  end

  field :ical do |plage_ouverture|
    Ics.to_ical(Ics.payload_for(plage_ouverture, :create))
  end
end
