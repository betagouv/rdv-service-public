class CreneauWizardForUsers::StartingConditions
  def initialize(prescripteur: nil, current_organisation: nil)
    @prescripteur = prescripteur
    @current_organisation = current_organisation
  end

  def prescription_interne?
    @prescripteur == Prescripteur::INTERNE
  end

  def prescripteur?
    @prescripteur.present?
  end

  attr_reader :current_organisation # Utilisé seulement pour la prescription interne
end
