class AiguillageAgentForm
  include ActiveModel::Model
  attr_accessor :raison

  def initialize(raison: nil)
    raison = raison.presence&.to_sym
    @raison = raison.in?(raisons_options.pluck(:value)) ? raison : nil
  end

  def raisons_options
    [
      { value: :gestion_agents, label: "Gérer les agents de mon organisation (ajout, suppression, droits)" },
      { value: :lieux_horaires, label: "Modifier un lieu ou des horaires" },
      { value: :motifs_rdv, label: "Créer ou modifier un motif de rendez-vous" },
      { value: :reservation_en_ligne, label: "Paramétrer la réservation en ligne ou les informations de mon organisation" },
      { value: :autre, label: "Autre raison" },
    ]
  end

  def raison_autre? = raison == :autre
  def raison_label = raisons_options.find { _1[:value] == raison }[:label]
  def should_redirect_to_demande_support? = raison_autre?
  def should_show_contact_admin_message? = raison.present? && !raison_autre?
end
