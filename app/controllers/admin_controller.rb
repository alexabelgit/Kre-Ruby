class AdminController < ApplicationController
  include CsvHeaders

  before_action :require_admin

  layout 'admin'

  protected

  def require_admin
    redirect_to root_url unless true_user&.admin?
  end
end
