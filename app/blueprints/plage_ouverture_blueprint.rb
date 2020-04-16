class PlageOuvertureBlueprint < Blueprinter::Base
  identifier :id

  fields :ical_uid, :title, :first_day, :start_time, :end_time
  association :agent, blueprint: AgentBlueprint
  association :organisation, blueprint: OrganisationBlueprint
  association :lieu, blueprint: LieuBlueprint
  association :motifs, blueprint: MotifBlueprint

  field :rrule do |plage_ouverture|
    ics = PlageOuverture::Ics.new(plage_ouverture: plage_ouverture)
    ics.rrule
  end

  field :ical do |plage_ouverture|
    ics = PlageOuverture::Ics.new(plage_ouverture: plage_ouverture)
    ics.to_ical
  end
end
