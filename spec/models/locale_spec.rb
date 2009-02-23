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

  it "should be invalid with no code" do
    Locale.create!(:code => "en")
    locale = Locale.new
    locale.should_not be_valid
  end
end


describe "English and Spanish Locales with I18n default locale set to English" do
  before(:each) do
    I18n.default_locale = "en"
    @english_locale = Locale.create!(:code => "en")
    @spanish_locale = Locale.create!(:code => "es")
  end

  it "should create a translated translation using english locale" do
    translation = @english_locale.create_translation('Hello World', 'Hello World')
    translation.key.should == Translation.hk('Hello World')
    translation.value.should == 'Hello World'
  end

  it "should create an untranslated translation using spanish locale" do
    translation = @spanish_locale.create_translation('Hello World', 'Hello World')
    translation.key.should == Translation.hk('Hello World')
    translation.value.should be_nil
  end

  it "should return default locale of English" do
    Locale.default_locale.should == @english_locale
  end

  it "should know that the english_locale is the default" do
    @english_locale.should be_default_locale
  end

  it "should know if it has a translation record" do
    translation = @english_locale.create_translation('key', 'Hello World')
    @english_locale.should have_translation('key')
  end
end

describe "Locale with translations" do
  before(:each) do
    I18n.default_locale = "en"
    @english_locale = Locale.create!(:code => "en")
    @spanish_locale = Locale.create!(:code => "es")

    @spanish_locale.translations.create!(:key => 'key1', :value => 'translated1')
    @spanish_locale.translations.create!(:key => 'key2', :value => 'translated2')
    @spanish_locale.translations.create!(:key => 'key3', :value =>  nil) # 1 untranslated record
  end

  it "should have 3 translations" do
    @spanish_locale.should have(3).translations
  end

  it "should have 1 untranslated" do
    @spanish_locale.translations.untranslated.should have(1).records
  end

  it "should have 2 translated" do
    @spanish_locale.translations.translated.should have(2).records
  end

  it "should have 67% translated" do
    @spanish_locale.percentage_translated.should == 67
  end

end
