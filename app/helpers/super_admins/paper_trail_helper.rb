module SuperAdmins
  module PaperTrailHelper
    # From "[Agent] Alain Sertion" to => "super_admins/agents/1"
    # From "[User] Patricia Duroy" to => "super_admins/users/1"
    def whodunnit_agent_or_user_url(paper_trail_name)
      return "" if paper_trail_name.blank?

      first_name, last_name = paper_trail_name.match(/\[.*\]\s(.*)/)[1].split
      klass = paper_trail_name.match(/\[(.*)\]/)[1].constantize
      return "" unless klass.in?([Agent, User])

      record = klass.find_by!("first_name ILIKE ? AND last_name ILIKE ?", first_name, last_name)
      send("super_admins_#{klass.name.downcase}_url", id: record.id)
    rescue StandardError
      ""
    end
  end
end
