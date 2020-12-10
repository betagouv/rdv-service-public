module DatesSpecHelper
  def get_next_week_working_weekday(weekday_name, consecutive_working_days: 1)
    d = Date.today.next_week(weekday_name)
    loop do
      return d if consecutive_working_days.times.none? { |offset| JoursFeriesService.includes?(d + offset.days) }

      d += 7.days
    end
  end
end
