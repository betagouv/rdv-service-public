module TodNilFix
  def initialize(h, m = 0, s = 0) # rubocop:disable Naming/MethodParameterName
    # En utilisant les helpers de formulaire Rails pour choisir heure et minute,
    # la valeur passée pour les secondes est alors `nil` et ce constructeur crashe.
    # On évite ici le crash en permettant au constructeur de recevoir des valeurs `nil`.
    m ||= 0
    s ||= 0

    super
  end
end

Tod::TimeOfDay.prepend(TodNilFix)
