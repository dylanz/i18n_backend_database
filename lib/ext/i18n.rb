module I18n
  class << self

    include ActionView::Helpers::AssetTagHelper

    def translate_asset(asset)
      locale = I18n.locale
      if File.exists?("#{ActionView::Helpers::AssetTagHelper::ASSETS_DIR}/#{locale}/#{image_path(asset)}")
        return "#{locale}#{image_path(asset) }"
      else
        return asset
      end
    end

    alias ta translate_asset

  end
end