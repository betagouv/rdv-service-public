module TransactionalSms::BaseConcern
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers

    attr_reader :user, :rdv

    delegate :phone_number_formatted, to: :user
  end

  def initialize(rdv, user)
    @user = user
    @rdv = rdv
  end

  def content
    raw_content.tr("áâãëẽêíïîĩóôõúûũçÀÁÂÃÈËẼÊÌÍÏÎĨÒÓÔÕÙÚÛŨ", "aaaeeeiiiiooouuucAAAAEEEEIIIIIOOOOUUUU")
  end

  def send!
    SendTransactionalSmsService.perform_with(self)
  end

  def tags
    [
      ENV["APP"],
      "dpt-#{rdv.organisation.departement}",
      "org-#{rdv.organisation.id}",
      self.class.name.demodulize.underscore
    ]
  end

  def rdv_footer
    message = if rdv.phone?
                "RDV Téléphonique\n"
              elsif rdv.home?
                "RDV à domicile\n#{rdv.address}\n"
              else
                "#{rdv.address_complete}\n"
              end
    message += "Infos et annulation: #{rdvs_shorten_url(host: ENV['HOST'])}"
    message += " / #{rdv.organisation.phone_number}" if rdv.organisation.phone_number
    message
  end

  def to_s
    "content: #{content} | recipient: #{phone_number_formatted} | tags: #{tags.join(',')}"
  end
end
