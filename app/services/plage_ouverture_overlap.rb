class PlageOuvertureOverlap
  attr_reader :po1, :po2

  def initialize(po1, po2)
    @po1 = po1
    @po2 = po2
  end

  def exists? # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return false if po1.agent != po2.agent

    if po1.exceptionnelle? && po2.exceptionnelle?
      both_exceptionnelles_overlap?
    else
      !po1_ends_before_po2? &&
        !po2_ends_before_po1? &&
        times_of_day_overlap? &&
        !both_weekly_but_different_days? &&
        !both_monthly_but_different_days? &&
        po1_occurrences_dates.any? { po2_occurrences_dates.include?(_1) }
    end
  end

  private

  def both_exceptionnelles_overlap?
    po1.starts_at < po2.ends_at && po1.ends_at > po2.starts_at
  end

  def po1_ends_before_po2?
    po1.ends_at && po1.ends_at < po2.starts_at
  end

  def po2_ends_before_po1?
    po2.ends_at && po2.ends_at < po1.starts_at
  end

  def both_weekly_but_different_days?
    return false unless po1.recurring? && po2.recurring?

    # both PO are weekly
    options1 = po1.recurrence
    options2 = po2.recurrence
    return false unless options1[:every] == "week" && options2[:every] == "week"
    return false if options1[:day].nil? || options2[:day].nil?

    # but are on different days
    # for monthly recurrences, day is [3] for the third day of the week
    options1[:day].intersection(options2[:day]).empty?
  end

  def both_monthly_but_different_days? # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return false unless po1.recurring? && po2.recurring?

    # both PO are monthly
    options1 = po1.recurrence
    options2 = po2.recurrence
    return false unless options1[:every] == "month" && options2[:every] == "month"
    return false if options1[:day].nil? || options2[:day].nil?

    # … but but are on different weeks
    # for monthly recurrences, day is {2=>[3]} for the second day of the third week of the month
    return true if options1[:day].keys.intersection(options2[:day].keys).empty?

    # … but are on the same week of the month but on different days
    # day is a hash, the key is the week number in the month, the value is the days in this week.
    # In RDVS, monthly PO are only on a single day per month
    return true if options1[:day].keys == options2[:day].keys && options1[:day].keys.size == 1 && options1[:day].values.first.intersection(options2[:day].values.first).empty?

    false
  end

  def times_of_day_overlap?
    po1.start_time < po2.end_time && po1.end_time > po2.start_time
  end

  def po1_occurrences_dates
    @po1_occurrences_dates ||= po1.occurrences_for(occurrences_date_range).map(&:to_date)
  end

  def po2_occurrences_dates
    @po2_occurrences_dates ||= po2.occurrences_for(occurrences_date_range).map(&:to_date)
  end

  def occurrences_date_range
    @occurrences_date_range ||= if po1.exceptionnelle?
                                  po1.first_day.past? ? nil : (po1.first_day..po1.first_day)
                                elsif po2.exceptionnelle?
                                  po2.first_day.past? ? nil : (po2.first_day..po2.first_day)
                                else
                                  min = [[po1.first_day, po2.first_day].min, Time.zone.today].max
                                  max = [po1.recurrence_ends_at, po2.recurrence_ends_at, 6.months.from_now].compact.min
                                  (min..max)
                                end
  end
end
