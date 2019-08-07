class Integrations::Shopify::OnboardingController < Integrations::ShopifyController

  def auto_injection
    SetupThemeWorker.perform_async(@store.id)
    respond_to do |format|
      format.js
    end
  end

  def auto_remove
    RemoveSnippetsWorker.perform_async(@store.id)
    respond_to do |format|
      format.js
    end
  end

  def check_embed_success
    CheckInstallationWorker.perform_in 20.seconds, @store.id
    respond_to do |format|
      format.js
    end
  end

end
