# frozen_string_literal: true

class Admin::Territories::NotificationSettingsController < Admin::Territories::BaseController
  def edit; end

  def update
    current_territory.update(notification_settings_params)
    redirect_to edit_admin_territory_notification_settings_path(current_territory)
  end

  private

  def notification_settings_params
    params.require(:territory).permit(:show_rdv_motif)
  end
end
