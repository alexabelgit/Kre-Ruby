class Callbacks::LemonstandController < CallbacksController

  before_action :parse_data

  def create
    trigger = @store.settings(:reviews).trigger.to_sym
    case params[:event]
    when 'order_paid', 'order_mark_paid', 'order_created', 'order_placed', 'order_updated', 'order_status_updated', 'order_deleted'
      SyncOrderWorker.perform_uniq_in(15.seconds, @store.id, @data['id'])
    end
    render body: nil, status: :ok
  end

  private

  def parse_data
    @store = Store.lemonstand.find_by_domain(request.headers['HTTP_X_LEMONSTAND_STORE_DOMAIN'])
    if request.headers['Content-Type'] == 'application/json'
      @data = JSON.parse(request.body.read)['data']
    else
      @data = params.as_json['data']
    end
  end

end
