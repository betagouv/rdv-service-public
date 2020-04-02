module MotifsHelper
  def motif_badges(motif)
    [
      motif.online ? content_tag(:span, 'En ligne', class: 'badge badge-danger') : nil,
      motif.phone? ? content_tag(:span, 'Par tél.', class: 'badge badge-info') : nil,
      Flipflop.visite_a_domicile? && motif.home? ? content_tag(:span, 'À domicile', class: 'badge badge-dark') : nil,
      motif.for_secretariat ? content_tag(:span, 'Secrétariat', class: 'badge badge-secondary') : nil,
    ].compact.presence&.sum
  end

  def min_max_delay_options
    [["1/2 heure", 30.minutes], ["1 heure", 1.hour], ["2 heures", 2.hours],
     ["3 heures", 3.hours], ["6 heures", 6.hours], ["12 heures", 12.hours],
     ["1 jour", 1.day], ["2 jours", 2.days], ["3 jours", 3.days], ["1 semaine", 1.week], ["2 semaines", 2.weeks],
     ["1 mois", 1.month], ["2 mois", 2.months], ["3 mois", 3.months], ["6 mois", 6.months], ["1 an", 1.year]]
  end
end
