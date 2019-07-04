module MotifsHelper

  def create_motif_button(btn_style = 'btn-primary')
    link_to "Créer un motif", new_organisation_motif_path(@organisation.id), class: "btn #{btn_style}", data: { rightbar: true } if policy(Motif).create?
  end

end
