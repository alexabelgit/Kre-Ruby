class OauthController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_after_action  :intercom_rails_auto_include
end
