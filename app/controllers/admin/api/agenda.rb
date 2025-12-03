module Admin::Api::Agenda
  def self.realtime_agenda_refresh?(current_territory)
    current_territory.id.even?
  end
end
