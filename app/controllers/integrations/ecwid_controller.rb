class Integrations::EcwidController < ApplicationController
  layout 'integrations/ecwid/back'

  before_action     :x_frame_options
  before_action     :authenticate_from_ecwid

  protected

  def x_frame_options
    response.headers['X-Frame-Options'] = 'my.ecwid.com'
  end

  def authenticate_from_ecwid
    return if params[:payload].blank?
    return if Rails.env.development?

    payload = decrypt_payload params[:payload]
    store = Store.find_by id_from_provider: payload[:store_id]

    if re_authenticate_via_oauth?(store)
      sign_out(current_user)
      redirect_to "/auth/ecwid"
    else
      sign_in(store.user) if current_user.blank?
      AhoyTracker.new(ahoy, store.user).authenticate.track('sign in', 'from Ecwid')
    end
  end

  def decrypt_payload(payload)
    HcCryptor.aes128 payload
  end

  def re_authenticate_via_oauth?(store)
    store.nil? || !store.installed? || store.user.deleted? ||
      (current_user.present? && store.user.id != current_user.id)
  end
end
