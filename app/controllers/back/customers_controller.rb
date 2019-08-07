class Back::CustomersController < BackController
  before_action :set_customer, only: [:show]

  def show
  end

  private

  def set_customer
    @customer = current_store.customers.find_by_hashid(params[:id])
  end
end
