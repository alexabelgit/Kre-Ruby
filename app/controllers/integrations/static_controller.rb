class Integrations::StaticController < ApplicationController

  skip_before_action :verify_authenticity_token
  skip_after_action  :intercom_rails_auto_include

  def widgets
    not_found unless Widgets.exists?(params[:widget])
    @store  = Store.find_by_id_from_provider_or_hashid(params[:store_id])
    @widget = params[:widget]
    respond_to do |format|
      format.js
    end
  end

end
