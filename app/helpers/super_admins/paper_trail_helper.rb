module SuperAdmins
  module PaperTrailHelper
    # From "[Agent] Alain Sertion" to => "super_admins/agents/Alain%20Sertion"
    # From "[User] Patricia Duroy" to => "super_admins/users/Patricia%20Duroy"
    def super_admins_url(paper_trail_name)
      return "" if paper_trail_name.blank?

      full_name = paper_trail_name.match(/\[.*\]\s(.*)/)[1]
      resource = paper_trail_name.match(/\[(.*)\]/)[1].downcase
      send("super_admins_#{resource}_url", id: full_name)
    end
  end
end
