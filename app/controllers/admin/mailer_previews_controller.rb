# adapted from https://github.com/rails/rails/blob/master/railties/lib/rails/mailers_controller.rb
# rubocop:disable all
module Admin
  class MailerPreviewsController < Admin::ApplicationController

    before_action :find_preview, only: :show
    around_action :set_locale, only: :show

    helper_method :part_query, :locale_query

    content_security_policy(false)

    def index
      @previews = ActionMailer::Preview.all
    end

    def show
      @email_action = File.basename(params[:id])
      if !@preview.email_exists?(@email_action)
        raise AbstractController::ActionNotFound, "Email '#{@email_action}' not found in #{@preview.name}"
      end

      @page_title = "Mailer Preview for #{@preview.preview_name}##{@email_action}"
      @email = @preview.call(@email_action, params)

      if params[:part]
        part_type = Mime::Type.lookup(params[:part])

        if part = find_part(part_type)
          response.content_type = part_type
          render plain: part.respond_to?(:decoded) ? part.decoded : part
        else
          raise AbstractController::ActionNotFound, "Email part '#{part_type}' not found in #{@preview.name}##{@email_action}"
        end
      else
        @part = find_preferred_part(request.format, Mime[:html], Mime[:text])
        render action: "email"
      end
    rescue ActiveRecord::RecordNotFound
      render plain: 'could not find preview AR instance'
    end

    private

    def find_preview
      candidates = []
      params[:id].to_s.scan(%r{/|$}) { candidates << $` }
      preview = candidates.detect { |candidate| ActionMailer::Preview.exists?(candidate) }

      if preview
        @preview = ActionMailer::Preview.find(preview)
      else
        raise AbstractController::ActionNotFound, "Mailer preview '#{params[:id]}' not found"
      end
    end

    def find_preferred_part(*formats) # :doc:
      formats.each do |format|
        if part = @email.find_first_mime_type(format)
          return part
        end
      end

      if formats.any? { |f| @email.mime_type == f }
        @email
      end
    end

    def find_part(format) # :doc:
      if part = @email.find_first_mime_type(format)
        part
      elsif @email.mime_type == format
        @email
      end
    end

    def part_query(mime_type)
      request.query_parameters.merge(part: mime_type).to_query
    end

    def locale_query(locale)
      request.query_parameters.merge(locale: locale).to_query
    end

    def set_locale
      I18n.with_locale(params[:locale] || I18n.default_locale) do
        yield
      end
    end
  end
end
# rubocop:enable all
