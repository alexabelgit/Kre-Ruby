module Admin
  class AddonPresenter
    attr_reader :view, :addon

    def initialize(addon, view = ActionView::Base.new)
      @addon = addon
      @view  = view
    end

    def chargebee?(addon_price)
      payment = PaymentProcessor.procesing_platform addon_price.ecommerce_platform
      payment == PaymentProcessor::CHARGEBEE
    end
  end
end
