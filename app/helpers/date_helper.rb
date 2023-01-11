# frozen_string_literal: true

module DateHelper
  def relative_date(date, fallback_format = :short)
    return if date.nil?

    date = date.to_date
    if date == Date.current
      I18n.t "date.helpers.today"
    elsif date == Date.current + 1
      I18n.t "date.helpers.tomorrow"
    else
      I18n.l(date, format: fallback_format)
    end
  end

  # true if the passed date (or time) is today or tomorrow
  def soon_date?(date)
    return false unless date.respond_to?(:to_date)

    [Date.current, Date.current + 1].include?(date.to_date)
  end
end
