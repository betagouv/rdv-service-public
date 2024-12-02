class AddCommentsForMetabase < ActiveRecord::Migration[7.0]
  def change
    change_column_comment(
      :agents,
      :display_saturdays,
      from: nil,
      to: <<~COMMENT
        Indique si l'agent veut que les samedis s'affichent quand il consulte un calendrier (pas forcément le sien). Cela n'affecte pas ce que voient les autres agents. Modifiable par le bouton en bas de la vue calendrier.
      COMMENT
    )

    change_column_comment(
      :agents, :display_cancelled_rdv,
      from: nil, to: <<~COMMENT
        Indique si l'agent veut que les rdv annulés s'affichent quand il consulte un calendrier (pas forcément le sien). Cela n'affecte pas ce que voient les autres agents. Modifiable par le bouton en bas de la vue calendrier
      COMMENT
    )

    change_column_comment(
      :agents, :account_deletion_warning_sent_at,
      from: nil, to: <<~COMMENT
        Quand le compte de l'agent est inactif depuis bientôt deux ans, on lui envoie un mail qui le prévient que sont compte sera bientôt supprimé, et qu'il doit se connecter à nouveau s'il souhaite conserver son compte. On enregistre la date d'envoi de cet email ici pour s'assure qu'on lui laisse un délai d'au moins un mois pour réagir.
      COMMENT
    )

    change_column_comment(
      :lieux, :availability,
      from: nil, to: <<~COMMENT
        Permet de savoir si le lieu est un lieu normal (enabled), un lieu ponctuel qui sera utilisé pour un seul rdv (single_use), ou un lieu supprimé par soft-delete (disabled). Dans la plupart des cas on s'intéresse uniquement aux lieux enabled
      COMMENT
    )

    change_column_comment(
      :motif_categories, :short_name,
      from: nil, to: <<~COMMENT
        Le nom "technique" de la catégorie de motif, qui permet de l'identifier dans les paramètres de formulaires"
      COMMENT
    )

    change_column_comment(
      :motifs, :min_public_booking_delay,
      from: nil, to: <<~COMMENT
        Permet de savoir combien de secondes il y aura au minimum entre la prise de rdv par un usager ou un prescripteur et le début du rdv. Par exemple si la valeur est 1800, et qu'il est 10h, le premier rdv qui pourra être pris (s'il y a une plage d'ouverture libre) sera à 10h30, puisque 1800 = 30 x 60. Cela permet à l'agent d'être prévenu suffisamment à l'avance.
      COMMENT
    )

    change_column_comment(
      :motifs, :max_public_booking_delay,
      from: nil, to: <<~COMMENT
        Permet de savoir combien de temps à l'avance il est possible de prendre rdv pour un usager ou un prescripteur. Le délai est mesuré en secondes. Cela évite que des gens prennent des rdv dans trop longtemps, et évite aux agents de s'engager à assurer des rdv alors qu'ils ne connaissent pas leur emploi du temps suffisamment à l'avance.
      COMMENT
    )

    change_column_comment(
      :motifs, :deleted_at,
      from: nil, to: <<~COMMENT
        Permet de savoir à quelle date le motif a été soft-deleted
      COMMENT
    )

    change_column_comment(
      :motifs, :restriction_for_rdv,
      from: nil, to: <<~COMMENT
        Instructions à accepter avant la prise du rendez-vous par l'usager
      COMMENT

    )
    change_column_comment(
      :motifs, :instruction_for_rdv,
      from: nil, to: <<~COMMENT
        Indications affichées à l'usager après la confirmation du rendez-vous. Apparait dans le mail de confirmation pour l'usager.
      COMMENT
    )

    change_column_comment(
      :motifs, :for_secretariat,
      from: nil, to: <<~COMMENT
        Permet aux agents du secrétariat d'assurer des rdv pour ce motif
      COMMENT
    )

    change_column_comment(
      :motifs, :follow_up,
      from: nil, to: <<~COMMENT
        Indique s'il s'agit d'un motif de suivi. Si c'est le cas, le rdv pourra uniquement être assuré par un agent référent de l'usager.
      COMMENT
    )

    change_column_comment(
      :motifs, :visibility_type,
      from: nil, to: <<~COMMENT
        Niveau de visibilité du motif pour l'usager. Cette option permet de cacher des rdvs sensibles pour assurer la sécurité d'un usager dont des proches pourraient consulter le téléphone ou le compte RDV Solidarités.
      COMMENT
    )

    change_column_comment(
      :motifs, :sectorisation_level,
      from: nil, to: <<~COMMENT
        Indique à quel point la sectorisation restreint la prise de rdv des usagers pour ce motif. Le niveau "departement" indique qu'il n'y a pas de restriction.
      COMMENT
    )

    change_column_comment(
      :motifs, :custom_cancel_warning_message,
      from: nil, to: <<~COMMENT
        Message d'avertissement montré à l'usager en cas d'annulation
      COMMENT
    )

    change_column_comment(
      :motifs, :collectif,
      from: nil, to: <<~COMMENT
        Indique s'il s'agit d'un rdv collectif ou individuel. Un rdv considéré comme individuel peut quand même avoir plusieurs participants, par exemple un parent et son enfant qui renouvellent tous les deux leur carte d'indentité en même temps. Un rdv collectif sera ouvert à plusieurs participants qui ne se connaissent pas entre eux.
      COMMENT
    )

    change_column_comment(
      :motifs, :location_type,
      from: nil, to: <<~COMMENT
        Là où le rdv aura lieu : "public_office" pour "Sur place" (généralement dans les bureaux de l'organisation), "phone" pour au téléphone (l'agent appelle l'usager), "home" pour le domicile de l'usager
      COMMENT
    )

    change_column_comment(
      :motifs, :rdvs_editable_by_user,
      from: nil, to: <<~COMMENT
        Indique si on autorise aux usagers de changer la date du rdv via l'interface web
      COMMENT
    )
  end
end
