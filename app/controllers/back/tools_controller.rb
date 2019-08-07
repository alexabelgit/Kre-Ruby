class Back::ToolsController < BackController
  skip_before_action :check_live, only: [:widget_console]

  before_action :update_auto_inject_try_performed, if: -> { @store.shopify? }
  before_action :check_widget_installation, only: [:onboarding, :widget_console], if: -> { @store.shopify? }

  def seed
  end

  def onboarding
  end

  def widget_console
    redirect_to back_dashboard_index_path unless @store.shopify?
  end

  def downloads
    redirect_to back_dashboard_index_path unless @store.downloads_enabled?

    @downloads = @store.downloads.ready.ordered.paginate(page: params[:page], per_page: 20)
  end

  def seed_orders
    redirect_to root_path if @store.custom?

    date_from =
      Date.civil(seed_params['date_from(1i)'].to_i,
                 seed_params['date_from(2i)'].to_i,
                 seed_params['date_from(3i)'].to_i)

    date_to =
      Date.civil(seed_params['date_to(1i)'].to_i,
                 seed_params['date_to(2i)'].to_i,
                 seed_params['date_to(3i)'].to_i)

    @date_valid = true

    if date_to < date_from
      @date_valid = false
      @message = 'From date should be older than To date'
    end

    if (Date.current - 1.year) > date_from
      @date_valid = false
      @message    = 'From date should be less than one year ago'
    end

    if @date_valid
      unless @store.settings(:background_workers).order_seed_running
        ImportOrdersWorker.perform_async(@store.id, date_from.to_s, date_to.to_s)
      end
    end

    respond_to do |format|
      format.js
    end
  end

  def seed_reviews_csv
    if setting_params[:file].present?
      csv = Array.csv_to_array(setting_params[:file])
      if csv
        if csv.empty?
          flash[:error] = 'The file is empty'
        else
          if Upload.check_columns(csv.first.keys, 'review', setting_params[:provider])
            current_store.settings(:background_workers).update_attributes(reviews_seed_running: true)
            ImportReviewsWorker.perform_async(@store.id, csv, setting_params[:provider])
          else
            flash[:error] = 'We could not process your CSV file, please make sure its columns match the provided template'
          end
        end
      else
        flash[:error] = 'Invalid CSV format'
      end
    end
    redirect_to seed_back_tools_path(anchor: 'import-reviews')
  end

  def seed_questions_csv
    if setting_params[:file].present?
      csv = Array.csv_to_array(setting_params[:file])
      if csv
        if csv.empty?
          flash[:error] = 'The file is empty' if csv.empty?
        else
          if Upload.check_columns(csv.first.keys, 'question', nil)
            current_store.settings(:background_workers).update_attributes(questions_seed_running: true)
            ImportQuestionsWorker.perform_async(@store.id, csv)
          else
            flash[:error] = 'We could not process your CSV file, please make sure its columns match the provided template'
          end
        end
      else
        flash[:error] = 'Invalid CSV format'
      end
    end
    redirect_to seed_back_tools_path(anchor: 'import-questions')
  end

  def update
    respond_to do |format|
      @store.change_template_language(setting_params[:locale]) if params[:change_templates].present? && params[:change_templates].to_b
      if @store.settings(params[:type].to_sym).update_attributes(setting_params)
        complete_global_settings_customized_step if setting_params[:default_name].present? || setting_params[:time_zone].present? || setting_params[:notify_customers_at]
        flash[:success] = 'Changes saved'
        format.html { redirect_to params[:redirect_to] }
        format.js   { render inline: redirect_js(params[:redirect_to] || request.referer || root_url) }
      else
        format.html { render params[:view] }
        format.js   { render inline: redirect_js(params[:redirect_to] || request.referer || root_url) }
      end
    end
  end

  private

  def update_auto_inject_try_performed
    should_be_truthy = @store.shopify_storefront_partially_set_up? && @store.setting_falsy?(:shopify, :auto_inject_try_performed)
    @store.update_settings(:shopify, auto_inject_try_performed: true) if should_be_truthy
  end

  def check_widget_installation
    if @store.setting_falsy? :shopify, :auto_inject_try_performed
      SetupThemeWorker.perform_in 5.seconds, @store.id
    elsif @store.show_shopify_check_installation?
      CheckInstallationWorker.perform_in 5.seconds, @store.id
    end
  end

  def setting_params
    params.require(:settings).permit!
  end

  def seed_params
    params.require(:seed).permit(:date_from, :date_to)
  end

end
