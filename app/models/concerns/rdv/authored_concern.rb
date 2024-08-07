module Rdv::AuthoredConcern
  extend ActiveSupport::Concern

  included do
    has_many :versions_where_event_eq_create,
             -> { where(event: "create") },
             class_name: "PaperTrail::Version",
             as: :item, dependent: :delete_all, inverse_of: :item
  end

  def author
    if created_by
      return created_by.full_name
    end

    # TODO: a partir du 10/01/2025, on pourra supprimer toute cette partie de la méthode qui utilise les versions, puisque
    # ça fera un an qu'on aura mis en production la pr https://github.com/betagouv/rdv-service-public/pull/3946
    # qui écrit les created_by
    creation_event = versions_where_event_eq_create.loaded? ? versions_where_event_eq_create.first : versions.where(event: "create").first
    whodunnit = creation_event&.whodunnit
    if whodunnit.blank?
      return "Dans le cadre du RGPD, cette information n'est plus conservée au delà d'un an."
    end

    if whodunnit.starts_with?("[User] ")
      whodunnit.gsub(/[User] \d* ?/, "")
    elsif whodunnit.starts_with?("[Agent] ")
      whodunnit.gsub(/\[Agent\] \d* ?/, "")
    else
      whodunnit
    end
  end
end
