module WithPassword
  extend ActiveSupport::Concern

  protected

  def generate_password
    Devise.friendly_token[0, 20]
  end
end
