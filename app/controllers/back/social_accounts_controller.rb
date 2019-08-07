class Back::SocialAccountsController < BackController

  require 'rest-client'

  before_action :set_social_account, only: [:destroy]

  def destroy
    # TODO clean up this mess @nkadze
    case @social_account.provider
      when 'facebook'
        current_store.koala.delete_object('me/permissions')
        current_store.settings(:social_accounts).facebook_page_id = nil
        current_store.save!
      when 'twitter'
        # TODO this does not work, but it should
        # twitter_client = current_store.twitter_client
        #twitter_client.invalidate_token(twitter_client.token)

        # TODO this does not work either (no wonder why :D)

        # auth_header = Base64.encode64("#{ENV['TWITTER_API_KEY']}:#{ENV['TWITTER_API_SECRET']}").squish
        # RestClient.post 'https://api.twitter.com/oauth2/invalidate_token',  params: { access_token: URI.decode(@social_account.access_token) },
        #                 header: {Authorization: "Basic #{auth_header}" }
        # uri              = URI.parse("https://api.twitter.com/oauth2/invalidate_token")
        # uri.query        = URI.encode_www_form(access_token: @social_account.access_token)
        # http             = Net::HTTP.new(uri.host, uri.port)cr
        # http.use_ssl     = true
        # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        # request          = Net::HTTP::Post.new(uri.request_uri)
        #
        # http.request(request).body
    end

    @social_account.destroy

    respond_to do |format|
      format.html { redirect_to social_accounts_back_settings_path, notice: "You have successfully disconnected HelpfulCrowd from your #{@social_account.provider.capitalize} account." }
      format.json { head :no_content }
    end
  end

  private

  def set_social_account
    @social_account = current_store.social_accounts.find_by_hashid(params[:id])
  end

end
