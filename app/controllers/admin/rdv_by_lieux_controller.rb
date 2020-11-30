class Admin::RdvByLieuxController < AgentAuthController
  def index
    @rdvs_per_lieu = {}
    policy_scope(Lieu).each { |lieu| @rdvs_per_lieu[lieu.name] = Rdv.for_today.with_lieu(lieu).count }
  end
end
