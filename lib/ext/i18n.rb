module I18n
  APP_DIRECTORY = 'app/views'

  class << self

    def translate_asset(asset)
      if locale_asset = locale_asset(asset)
        locale_asset
      else
        asset
      end
    end

    alias ta translate_asset

    def untranslated_assets(locale)
      assets = find_translated_assets(APP_DIRECTORY)
      assets.reject! {|asset| locale_asset_exists?(asset) }
      assets
    end

    def find_translated_assets(dir, search_string='I18n.ta')
      assets = []
      Dir.glob("#{dir}/*").each do |item|
        if File.directory?(item)
          assets += find_translated_assets(item, search_string)
        else
          File.readlines(item).each do |l|
            l.grep(/#{search_string}/) { |r| assets.push(r[/\('(.*?)'\)/, 1] || r[/\("(.*?)"\)/, 1]) }
          end
        end
      end
      assets
    end

    protected

    def locale_asset_exists?(asset)
      File.exists?("#{ActionView::Helpers::AssetTagHelper::ASSETS_DIR}/#{I18n.locale}#{asset_path(asset)}")
    end

    def locale_asset(asset)
      locale_asset_exists?(asset) ? "/#{I18n.locale}#{asset_path(asset)}" : nil
    end

    def asset_path(asset)
      asset[0] == ?/ ? asset : "/images/#{asset}"
    end

  end
end