# Nous stockons en base de données les dates de début et de fin sur la timezone Europe/Paris même si les RDV sont organisés
# dans des organisations qui peuvent être dans d'autres fuseaux horaires.
# Cela ne pose pas de problème pour la prise de RDV, car nous considérons toujours que les RDV sont effectués en heure locale.
# Cependant, lors de l’envoi de ces données à des systèmes externes (par API ou via les ICS), nous devons envoyer les dates
# dans le fuseau horaire de l’organisation.
# Ce concern permet donc de renvoyer les dates sur le bon fuseau horaire pour les réponses d’API.
# Pour les ICS, il nous suffit de spécifier le bon TZID dans le fichier ICS, et les clients de calendrier feront la conversion automatiquement.
module Rdv::TimezoneConcern
  extend ActiveSupport::Concern

  def starts_at_in_time_zone
    if organisation.time_zone.nil?
      starts_at
    else
      starts_at.change(zone: organisation.time_zone)
    end
  end

  def ends_at_in_time_zone
    if organisation.time_zone.nil?
      ends_at
    else
      ends_at.change(zone: organisation.time_zone)
    end
  end
end
