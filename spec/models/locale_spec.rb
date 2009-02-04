require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Locale do
  before(:each) do
    @valid_attributes = {
      :code => "en",
      :name => "English"
    }
  end

  it "should create a new instance given valid attributes" do
    Locale.create!(@valid_attributes)
  end

  it "should return code as to_param" do
    Locale.new(@valid_attributes).to_param.should == 'en'
  end

end

describe "English and Spanish Locales with I18n default locale set to English" do

  before(:each) do
    I18n.default_locale = "en"
    @english_locale = Locale.create!(:code => "en")
    @spanish_locale = Locale.create!(:code => "es")
  end

  it "should create a translated translation using english locale" do
    translation = @english_locale.find_or_create_translation('Hello World', 'Hello World')
    translation.key.should == 'Hello World'
    translation.value.should == 'Hello World'
  end

  it "should create an untranslated translation using spanish locale" do
    translation = @spanish_locale.find_or_create_translation('Hello World', 'Hello World')
    translation.key.should == 'Hello World'
    translation.value.should be_nil
  end

  it "should return default locale of English" do
    Locale.default_locale.should == @english_locale
  end

end
