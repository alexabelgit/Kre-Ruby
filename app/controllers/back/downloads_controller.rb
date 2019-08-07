module Back
  class DownloadsController < BackController
    HC_DOMAIN = '.helpfulcrowd.com'.freeze
    skip_before_action :check_live

    def show
      scope = current_user.admin? ? Download.all : @store&.downloads
      download = scope&.find_by_hashid params[:id]

      if download&.ready?
        download.signed_cookies.each { |key, value| cookies[key] = { value: value, domain: HC_DOMAIN } }
        redirect_to download.url
      else
        redirect_to downloads_back_tools_path
      end
    end
  end
end