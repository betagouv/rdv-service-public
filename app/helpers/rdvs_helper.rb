module RdvsHelper
  def pros_to_sentence(rdv)
    rdv.pros.map(&:full_name_and_specialite).to_sentence
  end
end
