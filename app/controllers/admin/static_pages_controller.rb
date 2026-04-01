class Admin::StaticPagesController < OrgaCentricController
  def support
    skip_authorization
  end
end
