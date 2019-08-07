class Integrations::Shopify::DashboardController < Integrations::ShopifyController
  def index
    redirect_to back_dashboard_index_url
  end
end
