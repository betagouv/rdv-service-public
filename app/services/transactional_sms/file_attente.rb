# frozen_string_literal: true

class TransactionalSms::FileAttente
  include TransactionalSms::BaseConcern

  def raw_content
    "Des créneaux se sont libérés plus tôt.\nCliquez pour voir les disponibilités : #{url}"
  end

  private

  def url
    users_creneaux_index_url(rdv_id: rdv.id, host: ENV["HOST"])
  end
end
