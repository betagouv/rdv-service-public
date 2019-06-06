class SpecialitesController < DashboardAuthController

  def index  
    @specialites = policy_scope(Specialite) 
    authorize(@specialites) 
  end

  def show  
    @specialite = policy_scope(Specialite).find(params[:id])
    @motifs = @specialite.motifs.where(organisation_id: current_pro.organisation_id)
    authorize(@specialite)  
  end

end