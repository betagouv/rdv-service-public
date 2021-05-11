# frozen_string_literal: true

class TransactionalSms::RdvUpdated
  include TransactionalSms::BaseConcern

  def raw_content
    body + rdv_footer
  end

  private

  def body
    "RDV modifié: #{rdv.motif.service.short_name} #{I18n.l(rdv.starts_at, format: (rdv.home? ? :short_approx : :short))}\n"
  end
end
