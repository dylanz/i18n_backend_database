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

    it "should find my test views" do
      I18n.find_translated_assets("./vendor/plugins/i18n_backend_database/spec/assets").should == ["promo/sfc08_140x400_3.gif", "image1.gif", 
                                                      "image2.gif", "icons/icon1.gif", "icons/icon2.gif", "/favicons/favicon1.gif", "/favicons/favicon2.gif"] 
    end

    describe "and locale en" do
      before(:each) do
        I18n.locale = "en"
      end

      it "should return default asset path" do
        I18n.ta("image.gif").should == 'image.gif'
      end

    end

    describe "and locale es" do
      before(:each) do
        I18n.locale = "es"
      end

      it "should return default asset path if no translated asset exists" do
       I18n.ta("image2.gif").should == 'image2.gif'
      end

      it "should return translated asset path if translatied asset exists" do
       I18n.ta("image1.gif").should == '/es/images/image1.gif'
      end

      it "should return untranslated assets" do
        I18n.untranslated_assets(:es).should == ["promo/sfc08_140x400_3.gif", "image2.gif", "icons/icon2.gif", "/favicons/favicon2.gif"]
      end

    end

  end

end
