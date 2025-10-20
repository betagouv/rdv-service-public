Rails.application.console do
  # Afin de pouvoir déboguer plus facilement en console, on désactive le filtrage des attributs
  # (filter_attributes permet de masquer certains attributs à l’appel de #inspect sur un objet).
  ActiveRecord::Base.filter_attributes = []
end
