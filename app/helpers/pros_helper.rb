module ProsHelper
  def current_pro?(pro)
    pro.id == current_pro.id
  end

  def me_tag(pro)
    content_tag(:span, 'Vous', class: 'badge badge-info') if current_pro?(pro)
  end

  def admin_tag(pro)
    content_tag(:span, 'Admin', class: 'badge badge-danger') if pro.admin?
  end

  def invite_button(btn_style = 'btn-primary')
    link_to 'Inviter un professionnel', new_pro_invitation_path, class: "btn #{btn_style}", data: { rightbar: true } if policy(current_pro).invite?
  end

  def delete_pro_dropdown_link(pro)
    link_to 'Supprimer', pro_path(pro), data: { confirm: "Êtes-vous sûr de vouloir supprimer cet utilisateur ?" }, method: :delete, class: 'dropdown-item' if policy(pro).destroy?
  end
end
