module RdvsHelper
  def pros_to_sentence(rdv)
    rdv.pros.map(&:full_name_and_specialite).sort.to_sentence
  end

  def human_location(rdv)
    rdv.location.blank? ? 'Non précisé' : rdv.location
  end
end
