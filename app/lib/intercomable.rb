module Intercomable
  def skip_intercom?
    Rails.env.development? && !intercom_config.debug_enabled
  end

  def intercom_config
    Rails.configuration.intercom
  end

  def intercom_api
    @intercom_api ||= Intercom::Client.new token: intercom_config.access_token,
                                           handle_rate_limit: intercom_config.handle_rate_limit
  end

end