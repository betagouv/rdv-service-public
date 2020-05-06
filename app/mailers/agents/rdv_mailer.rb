class Agents::RdvMailer < ApplicationMailer
  include ActionView::Helpers::DateHelper

  def rdv_starting_soon_created(rdv, agent)
    @rdv = rdv
    @agent = agent
    @date_str =
      if @rdv.starts_at.to_date == Date.tomorrow
        "demain"
      else
        "dans #{time_ago_in_words(@rdv.starts_at)}"
      end
    ics = Rdv::Ics.new(rdv: @rdv)
    attachments[ics.name] = {
      mime_type: 'text/calendar',
      content: ics.to_ical_for(agent),
    }
    mail(
      to: agent.email,
      subject: "Nouveau RDV #{@date_str} ajouté à votre agenda"
    )
  end
end
