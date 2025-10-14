class OnlineBookingOnboardingBanner
  def initialize(organisation)
    @organisation = organisation
  end

  def display?
    motifs_with_missing_availabilities.any?
  end

  def motifs_with_missing_availabilities
    @motifs_with_missing_availabilities ||= @organisation.motifs.active.bookable_by_everyone.select do |motif|
      motif.upcoming_availabilities.none?
    end
  end
end
