class Cloudinary::Assets
  require 'open-uri'

  def self.process_storefront_asset(original_file:, digest:, key:, name:, extension:, prefix: nil)
    asset_file = ExternalAsset.where(digest: digest, key: key, name: name, extension: extension).first
    return asset_file.url if asset_file.present?


    parsed_file = open(original_file).read
    if extension == 'css'
      url = Rails.configuration.urls_config.app_url
      parsed_file.gsub!('url("/assets', "url(\"#{url}/assets")
      parsed_file.gsub!('html#ecwid_html body#ecwid_body', prefix) if prefix.present?
    end
    file = Tempfile.new('foo')
    file.write(parsed_file.force_encoding('UTF-8'))
    file.close
    uploaded_file = Cloudinary::Uploader.upload(file.path,
                                                public_id: "storefront_assets/#{extension}/#{name}-#{key}-#{digest}.#{extension}",
                                                secure: true,
                                                resource_type: :raw)
    ExternalAsset.where(key: key, name: name, extension: extension).destroy_all
    Cloudinary::Api.delete_resources_by_prefix("storefront_assets/#{name}-#{key}")
    asset_file = ExternalAsset.create(digest: digest, key: key, extension: extension, name: name, url: uploaded_file['secure_url'])
    asset_file.url
  end


end
