# frozen_string_literal: true

# Cette classe sert principalement à gérer l'état transitoire pendant qu'on expérimente avec les prescripteurs
# dans le Var (83). On espère pouvoir la supprimer une fois que la réservation par prescripteurs sera ouverte
# plus largement (voir la PR https://github.com/betagouv/rdv-solidarites.fr/pull/3391)
class Admin::PrescripteurExperimentMotifPresenter < SimpleDelegator
  def bookable_by_label(bookable_by_value = bookable_by)
    case bookable_by_value.to_sym
    when :agents
      "Uniquement les agents de #{organisation.name}"
    when :agents_and_prescripteurs
      "Ouvert aux agents et aux prescripteurs"
    when :everyone
      if show_bookable_by_prescripteur?
        "Ouvert aux agents, aux prescripteurs et aux usagers"
      else
        "Ouvert aux agents et aux usagers"
      end
    end
  end

  def show_bookable_by_prescripteur?
    organisation.territory.departement_number.in?(%w[80 83]) || Rails.env.development?
  end

  def min_public_booking_delay_hint
    if show_bookable_by_prescripteur?
      "Les premiers créneaux proposés aux usagers et aux prescripteurs ne commenceront pas avant ce délai minimum"
    else
      "Les premiers créneaux proposés aux usagers ne commenceront pas avant ce délai minimum"
    end
  end

  def max_public_booking_delay_hint
    if show_bookable_by_prescripteur?
      "Les derniers créneaux proposés aux usagers et aux prescripteurs n'iront pas au delà de ce délai maximum"
    else
      "Les derniers créneaux proposés aux usagers n'iront pas au delà de ce délai maximum"
    end
  end
end
