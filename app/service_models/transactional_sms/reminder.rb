class TransactionalSms::Reminder
  include TransactionalSms::BaseConcern

  def raw_content
    body + rdv_footer
  end

  private

  def body
    "Rappel RDV #{@rdv.motif.service.short_name} le #{I18n.l(@rdv.starts_at, format: time_format)}\n"
  end

  def time_format
    @rdv.home? ? :short_approx : :short
  end
end
