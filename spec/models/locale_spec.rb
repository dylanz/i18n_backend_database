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
  
  it "should create a translated translation if none exists for default locale" do
    locale = Locale.create!(:code => "en")
    translation = locale.find_or_create_translation('Hello World', {})
    translation.key.should == 'Hello World'
    translation.value.should == 'Hello World'  
  end
  
  it "should create an untranslated translation if none exists for non-default locale" do
    locale = Locale.create!(:code => "es")
    translation = locale.find_or_create_translation('Hello World', {})
    translation.key.should == 'Hello World'
    translation.value.should be_nil  
  end
  
end
