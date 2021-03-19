class TransactionalSms::RdvCreated
  include TransactionalSms::BaseConcern

  def raw_content
    body + rdv_footer
  end

  private

  def body
    if rdv.home?
      "RDV #{rdv.motif.service.short_name} #{I18n.l(rdv.starts_at, format: :short_human_approx)}\n"
    else
      "RDV #{rdv.motif.service.short_name} #{I18n.l(rdv.starts_at, format: :short_human)}\n"
    end
  end
end
