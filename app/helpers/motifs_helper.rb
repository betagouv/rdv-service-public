module MotifsHelper
  def create_motif_button(btn_style = 'btn-primary')
    link_to "Créer un motif", new_organisation_motif_path(@organisation.id), class: "btn #{btn_style}", data: { rightbar: true } if policy(Motif).create?
  end

  def online_badge(motif)
    content_tag(:span, 'En ligne', class: 'badge badge-danger') if motif.online
  end

  def min_max_delay_options
    [["1/2 heure", 30.minutes], ["1 heure", 1.hour], ["2 heures", 2.hour],
     ["3 heures", 3.hour], ["6 heures", 6.hour], ["12 heures", 12.hour],
     ["1 jour", 1.day], ["2 jours", 2.day], ["3 jours", 3.day], ["1 semaine", 1.week], ["2 semaines", 1.week],
     ["1 mois", 1.month], ["2 mois", 2.month], ["3 mois", 3.month], ["6 mois", 6.month], ["1 an", 1.year]]
  end
end
