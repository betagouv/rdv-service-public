module StatsHelper
  def percent(number, total)
    return "" if total.zero?

    "#{(number * 100.0 / total).round}%"
  end
end
