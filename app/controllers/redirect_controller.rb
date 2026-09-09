class RedirectController < ApplicationController
  def rdv_short_from_token
    @participation = Participation.find_by!(restricted_auth_token: params[:tkn])

    redirect_to users_rdv_path(@participation.rdv, invitation_token: params[:tkn])
  end

  # << REMOVE AFTER 01/01/2027
  def rdv_short
    redirect_to users_rdv_path(params[:id], invitation_token: params[:tkn])
  end
  # >> REMOVE AFTER 01/01/2027

  def reprendre_rdv_from_participation_invitation_token
    participation = Participation.find_by(restricted_auth_token: params[:tkn])

    if participation
      redirect_to prendre_rdv_path_for(participation.rdv, params[:tkn])
    else
      redirect_to root_path, flash: { error: t("devise.invitations.invitation_token_invalid") }
    end
  end

  private

  def prendre_rdv_path_for(rdv, token)
    prendre_rdv_path(
      departement: rdv.organisation.departement_number,
      preselected_motif: rdv.motif&.public_link_id,
      public_link_organisation_id: rdv.organisation_id,
      lieu_id: rdv.lieu_id,
      address: rdv.address,
      invitation_token: token
    )
  end
end
