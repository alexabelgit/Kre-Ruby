# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.3'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path
#
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.precompile += %w[ admin.css back.css front.css mailer.css widgets.css ]

Rails.application.config.assets.precompile += %w[ admin.js back.js front.js ]

Rails.application.config.assets.precompile += %w( integrations/facebook.js integrations/facebook.css )

Rails.application.config.assets.precompile += %w( integrations/ecwid/back.js integrations/ecwid/front.js
                                                  integrations/ecwid.back.css integrations/ecwid/front.css )

Rails.application.config.assets.precompile += %w[ integrations/lemonstand/front.js integrations/lemonstand/front.css ]

Rails.application.config.assets.precompile += %w[ integrations/shopify/back.js integrations/shopify/front.js
                                                  integrations/shopify/redirect.js
                                                  integrations/shopify/back.css integrations/shopify/front.css ]

Rails.application.config.assets.precompile += %w( integrations/static/front.js )

Rails.application.config.assets.precompile += %w( plugins/cloudinary/upload-widget.css )

Rails.application.config.assets.precompile += %w( modernizr.js )
