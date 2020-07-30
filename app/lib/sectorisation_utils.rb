module SectorisationUtils
  def sectorisation_enabled?(departement)
    ENV["SECTORISATION_ENABLED_DEPARTMENT_LIST"]&.split&.include?(departement)
  end
end
