namespace :features do

  desc "Enable default features via Flipper"
  task enable_default: :environment do
    [:billing, :downloads, :orders_tracking].each do |feature|
      Flipper[feature].enable
    end
  end
end
