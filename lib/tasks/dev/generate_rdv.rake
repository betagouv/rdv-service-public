task generate_rdv: [:development] do
  Organisation.all.each do |organisation|
    (1..30).to_a.each do |n|
      (9..18).to_a.each do |j|
        motif = organisation.motifs.sample
        starts_at = Time.now.change(hour: j) + n.days
        user = organisation.users.sample
        break if !user
        Rdv.skip_callback(:create, :after, :send_notifications_to_users)
        Rdv.create!(name: "#{user.first_name} <> #{motif.name}", user_ids: [user.id], motif_id: motif.id, duration_in_min: motif.default_duration_in_min, starts_at: starts_at, organisation_id: organisation.id, agent_ids: organisation.agents.pluck(:id)) if ['Saturday', 'Sunday'].exclude?(starts_at.strftime('%A'))
        Rdv.set_callback(:create, :after, :send_notifications_to_users)
      end
    end
  end
end
