class Agents::RdvMailerPreview < ActionMailer::Preview
  def rdv_created
    rdv = Rdv.joins(:users).not_cancelled.last
    rdv.starts_at = 2.hours.from_now

    rdv_mailer(rdv).rdv_created
  end

  def rdv_revoked
    rdv = Rdv.joins(:users).last
    rdv.status = :revoked

    rdv_mailer(rdv).rdv_cancelled
  end

  def rdv_cancelled_by_agent
    rdv = Rdv.joins(:users).last
    rdv.status = :excused
    rdv_mailer(rdv).rdv_cancelled
  end

  def rdv_cancelled_by_user
    rdv = Rdv.joins(:users).last
    rdv.status = :excused

    rdv_mailer(rdv, rdv.users.first).rdv_cancelled
  end

  def rdv_updated
    rdv = Rdv.joins(:users).not_cancelled.last
    rdv.starts_at = Time.zone.today + 10.days + 10.hours

    rdv_mailer(rdv).rdv_updated(old_starts_at: 2.hours.from_now, lieu_id: nil)
  end

  def participation_cancelled
    organisation = Organisation.new(id: 10).tap(&:readonly!)
    user = User.new(first_name: "Mihaela", last_name: "MIRTU").tap(&:readonly!)
    participation = Participation.new(
      rdv: Rdv.new(
        id: 20,
        organisation:,
        users: [user],
        agents: [Agent.new(first_name: "Karim", last_name: "FERN", email: "karim@demo.rdv-solidarites.fr").tap(&:readonly!)],
        starts_at: Time.zone.today.next_occurring(:wednesday).at(Tod::TimeOfDay.parse("10:30")),
        duration_in_min: 30,
        motif: Motif.new(organisation:, name: "Atelier éducation canine", collectif: true).tap(&:readonly!),
        lieu: Lieu.new(organisation:, name: "Parc des bruyères, 13005 Marseille").tap(&:readonly!)
      ),
      user:
    ).tap(&:readonly!)
    agent = participation.rdv.agents.first
    Agents::RdvMailer.with(participation:, agent:, author: agent).participation_cancelled
  end

  private

  def rdv_mailer(rdv, author = rdv.agents.first)
    Agents::RdvMailer.with(rdv: rdv, agent: rdv.agents.first, author: author)
  end
end
