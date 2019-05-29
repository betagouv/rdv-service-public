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
end
