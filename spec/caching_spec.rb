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

      it "should find lowest level translation" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
      
        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}
      
        @backend.translate("en", :"models.translation.attributes.locale.blank", options).should == "is blank moron!"
        
        @backend.cache_store.exist?("en:#{Translation.hk("activerecord.errors.messages.models.translation.attributes.locale.blank")}:1").should be_true
        @backend.cache_store.exist?("en:#{Translation.hk("activerecord.errors.messages.models.translation.blank")}:1").should be_true
        @backend.cache_store.exist?("en:#{Translation.hk("activerecord.errors.messages.blank")}:1").should be_true

        @backend.cache_store.read("en:#{Translation.hk("activerecord.errors.messages.models.translation.attributes.locale.blank")}:1").should == nil
        @backend.cache_store.read("en:#{Translation.hk("activerecord.errors.messages.models.translation.blank")}:1").should == nil
        @backend.cache_store.read("en:#{Translation.hk("activerecord.errors.messages.blank")}:1").should == "is blank moron!"


        
      end

      
    end

  end
  
  
end
