class Back::SocialPostsController < BackController

  def create

    templates_path = self.send("update_social_templates_back_#{@postable.class.name.downcase.pluralize}_url", anchor: params[:provider])

    if params[:provider] == 'facebook'
      unless current_store.facebook_active?
        respond_to do |format|
          flash[:warning] = "Before posting you need to connect your HelpfulCrowd account with your #{params[:provider].capitalize} account."

          format.html { redirect_to social_accounts_back_settings_url(anchor: params[:provider]) }
          format.js   { render inline: redirect_js(social_accounts_back_settings_url(anchor: params[:provider])) }
        end
        return
      end

      if current_store.settings(@postable.class.name.downcase.pluralize.to_sym).facebook_post_template.blank?
        respond_to do |format|
          flash[:warning] = "Please provide templates which HelpfulCrowd will use to generate your social posts."

          format.html { redirect_to templates_path }
          format.js   { render inline: redirect_js(templates_path) }
        end
        return
      end
    elsif params[:provider] == 'twitter'
      unless current_store.twitter_active?
        respond_to do |format|
          flash[:warning] = "Before posting you need to connect your HelpfulCrowd account with your #{params[:provider].capitalize} account."

          format.html { redirect_to social_accounts_back_settings_url(anchor: params[:provider]) }
          format.js   { render inline: redirect_js(social_accounts_back_settings_url(anchor: params[:provider])) }
        end
        return
      end

      if current_store.settings(@postable.class.name.downcase.pluralize.to_sym).tweet_template.blank?
        respond_to do |format|
          flash[:warning] = "Please provide templates which HelpfulCrowd will use to generate your social posts."

          format.html { redirect_to templates_path }
          format.js   { render inline: redirect_js(templates_path) }
        end
        return
      end
    end

    @social_post          = SocialPost.new(provider: params[:provider])
    @social_post.postable = @postable

    if @social_post.save
      flash.now[:success] = "#{@postable.class.name} was posted on #{@social_post.provider.capitalize}.", :fade
    else
      flash.now[:error]   = "Failed to post #{@postable.class.name.downcase} on #{@social_post.provider.capitalize}, please try again."
    end

    respond_to do |format|
      format.html { render :show }
      format.js
    end
  end
end
