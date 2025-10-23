module FullCalendarHelper
  FC_SATURDAY = 6
  FC_SUNDAY = 0

  def fc_hidden_days_for(agent, territory = nil)
    hidden_days = []
    hidden_days.push(FC_SATURDAY) unless agent.display_saturdays
    hidden_days.push(FC_SUNDAY) unless territory&.work_on_sunday? && agent.display_saturdays
    hidden_days
  end
end
