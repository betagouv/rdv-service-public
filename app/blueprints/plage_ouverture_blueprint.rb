class PlageOuvertureBlueprint < Blueprinter::Base
  identifier :id

  fields :ical_uid, :title, :first_day, :start_time, :end_time
  association :agent, blueprint: AgentBlueprint
  association :organisation, blueprint: OrganisationBlueprint
  association :lieu, blueprint: LieuBlueprint
  association :motifs, blueprint: MotifBlueprint

  field :rrule do |plage_ouverture|
    Admin::Ics.rrule(plage_ouverture)
  end

  field :ical do |plage_ouverture|
    Admin::Ics.to_ical(Admin::Ics.payload_for(plage_ouverture))
  end
end
