class FeaturedImageUploader < CloudinaryUploader
  process resize_to_fit: [1920, 1080]
  process tags: ['featured_image']

  version :small do
    resize_to_fill 150, 100
  end

  version :thumb do
    resize_to_fill 90, 60
  end

  version :square_thumb do
    resize_to_fill 60, 60
  end

  def default_public_id
    ENV['DEFAULT_PUBLIC_ID_FOR_FEATURED_IMAGE']
  end

  def extension_whitelist
    %w(jpg jpeg gif png)
  end
end
