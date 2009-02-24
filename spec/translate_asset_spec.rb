require File.dirname(__FILE__) + '/spec_helper'

describe I18n do

  describe "with default locale en" do
    before(:each) do
      I18n.default_locale = "en"
      ActionView::Helpers::AssetTagHelper.send(:remove_const, :ASSETS_DIR)
      ActionView::Helpers::AssetTagHelper::ASSETS_DIR = "#{RAILS_ROOT}/vendor/plugins/i18n_backend_database/spec/assets/public"
      I18n.send(:remove_const, :APP_DIRECTORY)
      I18n::APP_DIRECTORY = "./vendor/plugins/i18n_backend_database/spec/assets"
    end

    describe "and locale en" do
      before(:each) do
        I18n.locale = "en"
      end

      it "should return default image path" do
        I18n.ta("image.gif").should == 'image.gif'
      end

    end

    describe "and locale es" do
      before(:each) do
        I18n.locale = "es"
      end

      it "should return default image path if no translation exists" do
       I18n.ta("image.gif").should == 'image.gif'
      end

      it "should return translated image path if translation exists" do
       I18n.ta("image2.gif").should == 'es/images/image2.gif'
      end

      it "should return untranslated images" do
        untranslated_assets = I18n.untranslated_assets(:es)
        untranslated_assets.should have(2).assets
        untranslated_assets.should include('rails.png')
        untranslated_assets.should include('promo/sfc08_140x400_3.gif')
      end

    end
  end

  it "should find my test views" do
    images = I18n.find_translated_images("./vendor/plugins/i18n_backend_database/spec/assets")
    images.should have(3).entries
    images.should include('rails.png')
    images.should include('image2.gif')
    images.should include('promo/sfc08_140x400_3.gif')
  end


end
