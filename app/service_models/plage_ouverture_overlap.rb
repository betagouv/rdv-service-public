class PlageOuvertureOverlap
  attr_reader :po1, :po2

  def initialize(po1, po2)
    @po1 = po1
    @po2 = po2
  end

  def exists?
    return false if po1.agent != po2.agent

    if po1.exceptionnelle? && po2.exceptionnelle?
      both_exceptionnelles_overlap?
    else
      !po1_ends_before_po2? &&
        !po2_ends_before_po1? &&
        times_of_day_overlap? &&
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
    @occurrences_date_range ||= begin
      if po1.exceptionnelle?
        po1.first_day.past? ? nil : (po1.first_day..po1.first_day)
      elsif po2.exceptionnelle?
        po2.first_day.past? ? nil : (po2.first_day..po2.first_day)
      else
        min = [[po1.first_day, po2.first_day].min, Date.today].max
        max = [po1.recurrence_until, po2.recurrence_until, 6.months.from_now].compact.min
        (min..max)
      end
    end
  end
end
