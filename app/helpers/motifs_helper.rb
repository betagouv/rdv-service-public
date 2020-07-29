module MotifsHelper
  def motif_name_with_location_type(motif)
    if motif.phone?
      motif.name + ' (Par tél.)'
    elsif motif.home?
      motif.name + ' (À domicile)'
    else
      motif.name
    end
  end

  def motif_name_with_badges(motif)
    content_tag(:span, motif.name) + motif_badges(motif)
  end

  def motif_badges(motif)
    badges = [:reservable_online, :phone, :home, :secretariat, :follow_up]
    badges.select { motif.send("#{_1}?") }.map { build_badge_tag_for(_1) }.join('').html_safe
  end

  def build_badge_tag_for(motif)
    content_tag(:span, I18n.t("motifs.badges.#{motif}"), class: "badge badge-motif-#{motif}")
  end

  def min_max_delay_options
    [['1/2 heure', 30.minutes], ['1 heure', 1.hour], ['2 heures', 2.hours],
     ['3 heures', 3.hours], ['6 heures', 6.hours], ['12 heures', 12.hours],
     ['1 jour', 1.day], ['2 jours', 2.days], ['3 jours', 3.days], ['1 semaine', 1.week], ['2 semaines', 2.weeks],
     ['1 mois', 1.month], ['2 mois', 2.months], ['3 mois', 3.months], ['6 mois', 6.months], ['1 an', 1.year]]
  end
end
