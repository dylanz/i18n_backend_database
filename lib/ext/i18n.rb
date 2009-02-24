module I18n
  APP_DIRECTORY = 'app/views'
  
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

    def untranslated_assets(locale)
      images = find_translated_images(APP_DIRECTORY)
      locale = I18n.locale
      images.reject! {|image| File.exists?("#{ActionView::Helpers::AssetTagHelper::ASSETS_DIR}/#{locale}/#{image_path(image)}") }
      images
    end

    def find_translated_images(dir, search_string='I18n.ta')
      images = []
      Dir.glob("#{dir}/*").each do |item|
        if File.directory?(item)
          images += find_translated_images(item, search_string)
        else
          File.readlines(item).each do |l|
            l.grep(/#{search_string}/) { |r| images.push(r[/\('(.*?)'\)/, 1] || r[/\("(.*?)"\)/, 1]) }
          end
        end
      end
      images
    end


  end
end