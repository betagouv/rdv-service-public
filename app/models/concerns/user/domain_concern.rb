# frozen_string_literal: true

module User::DomainConcern
  extend ActiveSupport::Concern

  # Cette méthode détermine le domaine de l'usager en se basant sur sa liste de RDVs :
  # - Si l'usager n'a pas de RDV, on retourne le domaine par défaut.
  # - Si tous les RDVs ont le même domaine, alors c'est le domaine de l'usager.
  # - Si les RDVs ont des domaines divers, on retourne le domaine du RDV le plus récent.
  #
  # Cette méthode est notamment utilisée par les mailers Devise (reset de mot de passe, inscription).
  # En effet, nous avions l'intention de faire en sorte que le domaine utilisé dans ces e-mails
  # soit le domaine à partir duquel la demande a été faite, mais c'était techniquement complexe.
  # Voir : https://stackoverflow.com/questions/49328228
  def domain
    return Domain::RDV_SOLIDARITES if rdvs.none?

    if rdvs.map(&:domain).uniq.size == 1
      # Si tous les RDVs ont le même domaine, alors c'est le domaine de l'usager.
      rdvs.first.domain
    else
      # Si les RDVs ont des domaines divers, on retourne le domaine du RDV le plus récent.
      rdvs.max_by(&:created_at).domain
    end
  end
end
