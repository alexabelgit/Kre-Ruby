class Back::Products::UploadController < BackController
  before_action :require_manage_products_permision

  def new
  end

  def create
    if upload_params[:file].present?
      csv = Array.csv_to_array(upload_params[:file])
      if csv
        if csv.empty?
          flash[:error] = 'The file is empty'
        else
          if Importers::ProductCsvImporter.valid_csv?(csv.first.keys)
            current_store.update_settings(:background_workers, uploading_products: true)
            UploadProductsWorker.perform_async(current_store.id, csv)
          else
            flash[:error] = 'We could not process your CSV file, please make sure its columns match the provided template'
          end
        end
      else
        flash[:error] = 'Invalid csv format'
      end
    end
    redirect_to back_products_upload_path
  end

  private

  def upload_params
    params.require(:upload).permit(:file)
  end

  def require_manage_products_permision
    redirect_to back_products_path unless current_store.manages_products?
  end
end
