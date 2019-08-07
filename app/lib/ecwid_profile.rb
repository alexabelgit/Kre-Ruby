class EcwidProfile

  def initialize(token, store_id, ecwid_api = EcwidApi::Client)
    @client = ecwid_api.new(store_id, token)
  end

  def account_email
    profile.dig('account', 'accountEmail')
  end

  def account_first_and_last_name
    first, last = profile.dig('account', 'accountName').presence.split(' ')
    [first || '.', last || '.']
  end

  def store_name
    profile.dig('settings', 'storeName')
  end

  def legal_name
    profile.dig('company', 'companyName').presence || store_name
  end

  def invoice_logo_url
    profile.dig('settings', 'invoiceLogoUrl')
  end

  def store_url
    profile.dig('generalInfo', 'storeUrl')
  end

  def phone
    profile.dig('company', 'phone')
  end

  def timezone
    profile.dig('formatsAndUnits', 'timezone')
  end

  def timezone?
    timezone.present?
  end

  def present?
    profile && !error_code
  end

  def error_code
    code = profile.dig('errorCode')
    code ? code.underscore.to_sym : nil
  end

  def error_message
    profile.dig('errorMessage')
  end

  private

  def profile
    @profile ||= @client.profile
  end
end
