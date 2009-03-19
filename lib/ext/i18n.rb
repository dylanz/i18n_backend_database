module I18n
  APP_DIRECTORY = 'app/views'

  class << self

    def locale_segment
      I18n.locale.to_s == I18n.default_locale.to_s ? "" : "/#{I18n.locale}"
    end
    alias :ls :locale_segment

    def localize_text(text, options = {})
      locale = options[:locale] || I18n.locale
      backend.localize_text(locale, text)
    end
    alias :lt :localize_text

    def tag_localized_text(text)
      backend.localize_text_tag + text + backend.localize_text_tag
    end
    alias :tlt :tag_localized_text

    def translate_asset(asset, options={})
      locale = options.delete(:locale) || I18n.locale
      if locale_asset = locale_asset(asset, locale)
        locale_asset
      else
        asset
      end
    end
    alias ta translate_asset

    def untranslated_assets(locale)
      return [] if locale.to_s == I18n.default_locale.to_s #default locale assets are assumed to exist
      assets = asset_translations
      assets.reject! {|asset| locale_asset_exists?(locale, asset) }
      assets
    end

    def asset_translations(dir=APP_DIRECTORY)
      assets = []
      Dir.glob("#{dir}/*").each do |item|
        if File.directory?(item)
          assets += asset_translations(item)
        else
          File.readlines(item).each do |l|
            assets += l.scan(/I18n.ta\(["'](.*?)["']\)/).flatten
          end
        end
      end
      assets.uniq
    end

    protected

    def locale_asset_exists?(locale, asset)
      File.exists?("#{ActionView::Helpers::AssetTagHelper::ASSETS_DIR}/#{locale}#{asset_path(asset)}")
    end

    def locale_asset(asset, locale)
      locale_asset_exists?(locale, asset) ? "/#{locale}#{asset_path(asset)}" : nil
    end

    def asset_path(asset)
      asset[0] == ?/ ? asset : "/images/#{asset}"
    end

  end
end