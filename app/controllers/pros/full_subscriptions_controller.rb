class Pros::FullSubscriptionsController < DashboardAuthController

  layout 'registration'
  
  def new  
    @subscription = Pro::FullSubscription.new(pro: current_pro, first_name: current_pro.first_name, last_name: current_pro.last_name)
    authorize(@subscription)
  end

  def create
    build_subscription
    authorize(@subscription)
    if @subscription.save
      redirect_to authenticated_root_path(_conversion: 'account-creation')
    else
      render 'new'
    end
  end

  private 
  def build_subscription
    @subscription = Pro::FullSubscription.new(full_subscription_params)
    @subscription.pro = current_pro
  end

  def full_subscription_params
    params.require(:pro_full_subscription).permit(:first_name, :last_name)
  end

end
