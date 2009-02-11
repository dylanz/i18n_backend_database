require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Translation do
  before(:each) do
    @valid_attributes = {
      :key   => "Hello World",
      :value => "Hello World"
    }
  end

  it "should create a new instance given valid attributes" do
    Translation.create!(@valid_attributes)
  end

end

describe "English and Spanish Locales with I18n default locale set to English" do

  before(:each) do
    I18n.default_locale = "en"
    @english_locale = Locale.create!(:code => "en")
    @spanish_locale = Locale.create!(:code => "es")
  end

  describe "with no English translation" do

    it "should have return 'No default locale value' for a new Spanish translation with same key" do
      @spanish_translation = @spanish_locale.translations.create(:key => 'Hello World')
      @spanish_translation.default_locale_value.should == 'Hello World'  
    end

  end

  describe "with one English translation" do

    before(:each) do
      @english_translation = @english_locale.translations.create(:key => 'Hello World', :value => 'Hello World')
    end

    it "should have a default locale value" do
      @english_translation.default_locale_value.should == 'Hello World'  
    end

    it "should have a default locale value of the English for a new Spanish translation with same key" do
      @spanish_translation = @spanish_locale.translations.create(:key => 'Hello World')
      @spanish_translation.default_locale_value.should == 'Hello World'  
    end

  end

end
