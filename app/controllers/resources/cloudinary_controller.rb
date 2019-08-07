class Resources::CloudinaryController < ResourcesController

  def signature
    data = params[:data]
    if data.present?
      data = {callback: data[:callback], upload_preset: data[:upload_preset], timestamp: data[:timestamp]}
      render plain: Cloudinary::Utils.api_sign_request(data, Rails.configuration.cloudinary.api_secret)
    end
  end

  def styles
    render plain: Cloudinary::Assets.process_storefront_asset(original_file: asset_path('plugins/cloudinary/upload-widget.css'),
                                                              digest:        asset_digest('plugins/cloudinary/upload-widget', 'css'),
                                                              key:           'cloudify',
                                                              name:          'hc-cloudify-style',
                                                              extension:     'css',
                                                              prefix:        params[:prefix])
  end

end
