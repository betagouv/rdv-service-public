module DateHelper
  def relative_date(date, fallback_format = :short)
    return if date.nil?

    date = date.to_date
    if date == Date.current
      "aujourd’hui"
    elsif date == Date.current + 1
      "demain"
    else
      "le #{I18n.l(date, format: fallback_format)}"
    end
  end

  def relative_date_with_preposition(date, fallback_format = :short)
    return if date.nil?

    date_obj = date.to_date
    if date_obj == Date.current
      "d'aujourd'hui"
    elsif date_obj == Date.current + 1
      "de demain"
    else
      "du #{I18n.l(date_obj, format: fallback_format)}"
    end
  end

  # true if the passed date (or time) is today or tomorrow
  def soon_date?(date)
    return false unless date.respond_to?(:to_date)

    [Date.current, Date.current + 1].include?(date.to_date)
  end

  def human_date_format(date)
    if date.year == Time.zone.now.year
      I18n.l(date, format: :human_without_year)
    else
      I18n.l(date, format: :human)
    end
  end
end
