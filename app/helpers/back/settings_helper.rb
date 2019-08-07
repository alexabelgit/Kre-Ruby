module Back::SettingsHelper
  def facebook_oauth_path
    "/auth/facebook"
  end

  def twitter_oauth_path
    "/auth/twitter"
  end
end
