# frozen_string_literal: true

module DateHelper
  def relative_date(date, fallback_format = :short)
    date = date.to_date
    if date == Date.current
      t "date.helpers.today"
    elsif date == Date.current + 1
      t "date.helpers.tomorrow"
    else
      l(date, format: fallback_format)
    end
  end
end
