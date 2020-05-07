class Agents::RdvMailer < ApplicationMailer
  def rdv_starting_soon_created(rdv, agent)
    @rdv = rdv
    @agent = agent
    @date_str = {
      Date.today => "aujourd'hui",
      Date.tomorrow => "demain",
    }[@rdv.starts_at.to_date]
    mail(
      to: agent.email,
      subject: "Nouveau RDV ajouté sur votre agenda rdv-solidarités pour #{@date_str}"
    )
  end
end
