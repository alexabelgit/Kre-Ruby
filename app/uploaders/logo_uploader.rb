class LogoUploader < CloudinaryUploader

  process convert: 'png'
  process tags: ['store_logo']

  process resize_to_fit: [480, 480]

  version :small do
    process resize_to_fit: [160, 160]
  end

  version :tiny do
    process resize_to_fit: [80, 80]
  end

  def extension_whitelist
    %w(jpg jpeg gif png)
  end

end
