class CloudinaryUploader < CarrierWave::Uploader::Base
  include Cloudinary::CarrierWave

  def public_id
    hashid = model.persisted? ? model.hashid : 'no-hashid'
    if model.is_a?(Store)
      "#{model.class.name.downcase.pluralize}/#{hashid}/store_object/#{mounted_as}"
    elsif model.respond_to?(:store)
      "stores/#{model.store.hashid}/#{model.class.name.downcase.pluralize}/#{hashid}/#{mounted_as}"
    else
      "#{model.class.name.downcase.pluralize}/#{hashid}/#{mounted_as}"
    end
  end

end
