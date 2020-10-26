class Users::CreneauSearch
  include Users::CreneauxSearchConcern

  def initialize(user:, motif:, lieu:, starts_at:, geo_search: nil)
    @user = user
    @motif = motif
    @lieu = lieu
    @starts_at = starts_at
    @geo_search = geo_search
  end

  def creneau
    creneaux.select { _1.starts_at == @starts_at }.sample
  end

  def next_availability
    nil
  end

  def self.creneau_for(*args, **kwargs)
    new(*args, **kwargs).creneau # simplifies testing
  end

  protected

  def motifs
    [@motif]
  end

  def motif_location_type
    @motif.location_type
  end

  def date_range
    (@starts_at.to_date..(@starts_at + 1.day).to_date)
  end
end
