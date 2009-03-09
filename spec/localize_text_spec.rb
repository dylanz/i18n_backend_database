require File.dirname(__FILE__) + '/spec_helper'

describe I18n::Backend::Database do
  before(:each) do
    @backend = I18n::Backend::Database.new
  end

  after(:each) do
    @backend.cache_store.clear
  end

  describe "with default locale en" do
    before(:each) do
      I18n.default_locale = "en"
      @english_locale = Locale.create!(:code => "en")
    end

    describe "and locale en" do
      before(:each) do
        I18n.locale = "en"
      end

      it "should localize tagged text" do
        @backend.localize_text("en", "shane ^^is now friends with^^ dylan").should == "shane is now friends with dylan"
      end

      it "should localize text tagged more than once" do
        @backend.localize_text("en", "dylan ^^is now friends with^^ shane ^^and is happy, ^^dylan ^^claps his hands!^^").should == "dylan is now friends with shane and is happy, dylan claps his hands!"
      end

      it "should localize tagged text using class method" do
        I18n.localize_text("shane ^^is now friends with^^ dylan").should == "shane is now friends with dylan"
      end

      it "should localize tagged text using class method alias" do
        I18n.lt("shane ^^is now friends with^^ dylan").should == "shane is now friends with dylan"
      end

      it "should add localize text tags" do
        I18n.tag_localized_text("is now friends with").should == "^^is now friends with^^"
      end

      it "should add localize text tags using alias" do
        I18n.tlt("is now friends with").should == "^^is now friends with^^"
      end

      it "should just return text with no localize text tags" do
        @backend.localize_text("en", "shane is now friends with dylan").should == "shane is now friends with dylan"
      end

      it "should localize tagged text using custom localize text tag" do
        @backend.localize_text_tag = "##"
        @backend.localize_text("en", "shane ##is now friends with## dylan").should == "shane is now friends with dylan"
      end

      it "should localize tagged text using another custom localize text tag" do
        @backend.localize_text_tag = "LOCALIZED_TEXT_TAG"
        @backend.localize_text("en", "shane LOCALIZED_TEXT_TAGis now friends withLOCALIZED_TEXT_TAG dylan").should == "shane is now friends with dylan"
      end

    end

    describe "and locale es" do
      before(:each) do
        I18n.locale = "es"
        @spanish_locale = Locale.create!(:code => 'es')
      end

      it "should localize tagged text" do
        @spanish_locale.translations.create!(:key => 'is now friends with', :value => 'ahora es con amigos')
        @backend.localize_text("es", "shane ^^is now friends with^^ dylan").should == "shane ahora es con amigos dylan"
      end

    end
  end
end
