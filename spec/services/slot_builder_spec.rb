# frozen_string_literal: true

describe SlotBuilder, type: :service do

  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture 
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 10 décembre 2020 à 9 h 30
  # - du 10 décembre 2020 à 10 h
  # - du 10 décembre 2020 à 10 h 30
  #

  #
  # avec
  # - une absence le 10 décembre 2020 de 9 h 45 à 10 h 15
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture 
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 10 décembre 2020 à 10 h 15
  # - du 10 décembre 2020 à 10 h 45


  #
  # avec
  # - une absence du 10 décembre 2020 à 9 h 45 qui fini le 11 décembre 2020 à 6 h 30
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture 
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 11 décembre 2020 à 9 h
  # - du 11 décembre 2020 à 9 h 30
  # - du 11 décembre 2020 à 10 h
  # - du 11 décembre 2020 à 10 h 30


  #
  # avec
  # - une absence du 10 décembre 2020 à 9 h 45 qui fini le 11 décembre 2020 à 9 h 05
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture 
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 11 décembre 2020 à 9 h 05
  # - du 11 décembre 2020 à 9 h 35
  # - du 11 décembre 2020 à 10 h 05


  #
  # avec
  # - une absence du jeudi 3 décembre 2020 à 9 h 45 qui fini le jeudi 3 décembre 2020 à 10 h 15 qui se répète toutes les semaines
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 10 décembre 2020 à 10 h 15
  # - du 10 décembre 2020 à 10 h 45


  #
  # avec
  # - un RDV le jeudi 10 décembre 2020 à 9 h 30 qui fini le jeudi 3 décembre 2020 à 10 h
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 10 décembre 2020 à 10 h
  # - du 10 décembre 2020 à 10 h 30


  #
  # avec
  # - un RDV le jeudi 10 décembre 2020 à 9 h 30 qui fini le jeudi 3 décembre 2020 à 9 h 45
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 10 décembre 2020 à 9 h 45
  # - du 10 décembre 2020 à 10 h 15
  # - du 10 décembre 2020 à 10 h 45

  #
  # avec
  # - un RDV le jeudi 10 décembre 2020 à 9 h 30 qui fini le jeudi 3 décembre 2020 à 10 h 15
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 10 décembre 2020 à 10 h 15
  # - du 10 décembre 2020 à 10 h 45

  #
  # avec
  # - un RDV ANNULÉ le jeudi 10 décembre 2020 à 9 h 30 qui fini le jeudi 3 décembre 2020 à 10 h
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 10 décembre 2020 à 9 h
  # - du 10 décembre 2020 à 9 h 30
  # - du 10 décembre 2020 à 10 h
  # - du 10 décembre 2020 à 10 h 30

  # avec
  # - un jour fériée
  # - aujourd'hui étant le 1 janvier 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être vide
  # -- NOTE YAF: en même temps, s'il n'y a pas de plage d'ouverture sur ce jour là...

  # avec
  # - un RDV le jeudi 16 décembre 2020 à 10 h qui fini le jeudi 16 décembre 2020 à 10 h 30
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 16 décembre 2020 à 9 h
  #   - qui fini à 11 h
  #   - pour un agent donnée
  #   - qui se répète tout les jours à partir du 10 décembre 2020
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 9 h
  # - du 16 décembre 2020 à 9 h 30
  # - du 16 décembre 2020 à 10 h


  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 10 h
  #   - qui fini à 12 h
  #   - pour un autre agent
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 9 h
  # - du 16 décembre 2020 à 9 h 30
  # - du 16 décembre 2020 à 10 h
  # - du 16 décembre 2020 à 10 h 30
  # - du 16 décembre 2020 à 11 h
  # - du 16 décembre 2020 à 11 h 30

  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent A
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 10 h
  #   - qui fini à 12 h
  #   - pour un autre agent B
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020 POUR les agents
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 9 h pour l'agent A
  # - du 16 décembre 2020 à 9 h 30 pour l'agent A
  # - du 16 décembre 2020 à 10 h pour l'agent A
  # - du 16 décembre 2020 à 10 h pour l'agent B
  # - du 16 décembre 2020 à 10 h 30 pour l'agent A
  # - du 16 décembre 2020 à 10 h 30 pour l'agent B
  # - du 16 décembre 2020 à 11 h pour l'agent B
  # - du 16 décembre 2020 à 11 h 30 pour l'agent B


  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent A
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 10 h
  #   - qui fini à 12 h
  #   - pour un autre agent B
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020 POUR l'agent B
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 10 h pour l'agent B
  # - du 16 décembre 2020 à 10 h 30 pour l'agent B
  # - du 16 décembre 2020 à 11 h pour l'agent B
  # - du 16 décembre 2020 à 11 h 30 pour l'agent B

  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent A
  # - une plage d'ouverture
  #   - qui démarre le 10 décembre 2020 à 10 h
  #   - qui fini à 12 h
  #   - pour un autre agent B
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020 POUR aucun agent
  #
  # Le résultat doit être vide

  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif nomé A sur place d'une durée de 30 minutes
  # - un motif nomé A à domicile d'une durée de 30 minutes
  # - une plage d'ouverture
  #   - pour les deux motif nomé A
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  #   - pour un agent
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020 un agent pour un agent filtré sur les motifs à domicile
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 10 h pour le motif A à domicile
  # - du 16 décembre 2020 à 10 h 30 pour le motif A à domicile
  # - du 16 décembre 2020 à 11 h pour le motif A à domicile
  # - du 16 décembre 2020 à 11 h 30 pour le motif A à domicile


  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif d'un service A nomé MonMotif
  # - un motif d'un service B nomé MonMotif
  # - une plage d'ouverture
  #   - pour le motif du service A
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  # - une plage d'ouverture
  #   - pour le motif du service B
  #   - qui démarre le 10 décembre 2020 à 14 h
  #   - qui fini à 13 h 35
  # - la date du jour au 10 décembre 2020 à 8 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020 pour le service A
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 9 h pour le motif du service A
  # - du 16 décembre 2020 à 9 h 30 pour le motif du service A
  # - du 16 décembre 2020 à 10 h pour le motif du service A
  # - du 16 décembre 2020 à 10 h 30 pour le motif du service A
  # - du 16 décembre 2020 à 11 h pour le motif du service A
  # - du 16 décembre 2020 à 11 h 30 pour le motif du service A ???? TRÈS BIZARRE !
  # - du 16 décembre 2020 à 14 h pour le motif du service B


  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif avec un min booking_delay de 30 minutes
  # - une plage d'ouverture
  #   - pour le motif
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  # - la date du jour au 10 décembre 2020 à 9 h 15
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 10 h pour le motif du service A
  # - du 16 décembre 2020 à 10 h 30 pour le motif du service A
  #
  # Pourquoi pas le 9 h 30 ?


  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif avec un max booking_delay de 45 minutes
  # - une plage d'ouverture
  #   - pour le motif
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  # - la date du jour au 10 décembre 2020 à 9 h 15
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 10 h pour le motif du service A
  #
  # Pourquoi pas le 9 h 30 ?

  # avec
  # - aujourd'hui étant le 10 décembre 2020
  # - un motif
  # - une plage d'ouverture
  #   - pour le motif
  #   - qui démarre le 10 décembre 2020 à 9 h
  #   - qui fini à 11 h 20
  # - la date du jour au 10 décembre 2020 à 10 h
  #
  # Si on demande les créneaux pour la période du 10 décembre 2020 au 17 décembre 2020
  #
  # Le résultat doit être
  # - du 16 décembre 2020 à 10 h 30 pour le motif du service A ?
  #

end
