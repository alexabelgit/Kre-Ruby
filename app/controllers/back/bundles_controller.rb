module Back
  class BundlesController < BackController
    skip_before_action :check_live

    def show
      bundle = current_store.bundles.find_by params[:id]
      @presenter = BundlePresenter.new(bundle, view_context)
      if request.xhr?
        render partial: 'show', locals: { bundle: @presenter }
      end
    end

    def preview
      bundle = current_store.bundles.find_by id: params[:id]
      if !bundle&.draft?
        bundle = find_or_create_draft_bundle current_store
      end

      outcome  = Bundles::PreviewBundle.run bundle: bundle,
                                            plan_id: params[:plan],
                                            addon_price_ids: params[:addons]

      if request.xhr?
        if current_store.subscription?
          old_bundle = current_store.active_bundle
          presenter = UpgradeBundlePresenter.new(outcome.result, old_bundle, view_context)
          render partial: 'upgrade', locals: { bundle: presenter }

        else
          presenter = BundlePresenter.new(outcome.result, view_context)
          render partial: 'show', locals: { bundle: presenter }
        end
      end
    end

    private

    def find_or_create_draft_bundle(store)
      store.draft_bundle || Bundles::CreateBundle.run(store: store)
    end
  end
end
