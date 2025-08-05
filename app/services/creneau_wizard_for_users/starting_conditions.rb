class CreneauWizardForUsers::StartingConditions
  def initialize(prescripteur: nil)
    @prescripteur = prescripteur
  end

  def prescription_interne?
    @prescripteur == Prescripteur::INTERNE
  end
end
