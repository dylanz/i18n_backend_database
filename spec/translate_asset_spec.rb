require File.dirname(__FILE__) + '/spec_helper'

describe I18n do

  describe "with default locale en" do
    before(:each) do
      I18n.default_locale = "en"
      ActionView::Helpers::AssetTagHelper.send(:remove_const, :ASSETS_DIR)
      ActionView::Helpers::AssetTagHelper::ASSETS_DIR = "#{RAILS_ROOT}/vendor/plugins/i18n_backend_database/spec/assets/public"
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

    end
  end

  it "should find my test views" do
    test_dir = "./vendor/plugins/i18n_backend_database/spec/assets"
    images = Translation.find_image_tags(test_dir)
    images.should have(2).entries
    images.should include('rails.png')
    images.should include('promo/sfc08_140x400_3.gif')
  end


end
