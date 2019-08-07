class ResourcesController < ApplicationController
  after_action      :embedded_storefront
  skip_after_action :intercom_rails_auto_include

  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }

  protected

  def asset_path(file)
    URI.join(root_url, ActionController::Base.helpers.asset_path(file)).to_s
  end

  def asset_digest(file, extension)
    ActionController::Base.helpers.asset_path("#{file}.#{extension}").split("#{file}-").last.gsub(".#{extension}", '')
  end

  def embedded_storefront
    response.headers['Access-Control-Allow-Origin']      = request.headers['origin']
    response.headers['Access-Control-Allow-Credentials'] = true
    response.headers['Access-Control-Allow-Methods']     = 'POST, PUT, DELETE, GET, OPTIONS, PATCH'
  end

end