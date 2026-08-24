class OnlineBookingOnboardingBanner
  # `motifs` doit déjà être scopé selon ce que l'agent courant a le droit de voir
  # (ex : Agent::MotifPolicy::Scope), pour ne pas inviter l'agent à agir sur des motifs
  # appartenant à des services auxquels il n'a pas accès.
  def initialize(motifs)
    @motifs = motifs
  end

  def availabilities_needed?
    motifs_with_missing_availabilities.any?
  end

  def motifs_with_missing_availabilities
    @motifs_with_missing_availabilities ||= @motifs.active.bookable_by_everyone.select do |motif|
      motif.upcoming_availabilities.none?
    end
  end
end
