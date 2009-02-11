require File.dirname(__FILE__) + '/spec_helper'

describe I18n::Backend::Database do
  
  before(:each) do
    @backend = I18n::Backend::Database.new
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

      it "should create a record with the key as the value when the key is a string" do
        @backend.translate("en", "String").should == "String"
        @english_locale.should have(1).translation
        @english_locale.translations.first.key.should == "String"
        @english_locale.translations.first.value.should == "String"
      end
      
      it "should find a record with the key as the value when the key is a string" do
        @english_locale.translations.create!(:key => 'String', :value => 'Value')
        @backend.translate("en", "String").should == "Value"
        @english_locale.should have(1).translation
      end

      it "should be able to handle interpolated values" do
        options = {:count=>1, :model => ["Cheese"], :scope=>[:activerecord, :errors], :default=>["Locale"]}
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => '{{count}} errors prohibited this {{model}} from being saved')
        @backend.translate("en", :"messages.blank", options).should == '1 errors prohibited this Cheese from being saved'
      end

      it "should be able to handle pluralization" do
        @english_locale.translations.create!(:key => 'activerecord.errors.template.header', :value => '1 error prohibited this {{model}} from being saved', :pluralization_index => 1)
        @english_locale.translations.create!(:key => 'activerecord.errors.template.header', :value => '{{count}} errors prohibited this {{model}} from being saved', :pluralization_index => 0)

        optiona = {:sount=>1, :model=>"translation", :scope=>[:activerecord, :errors, :template]}
        @backend.translate("en", :"header", options).should == "1 error prohibited this translation from being saved"
        @english_locale.should have(2).translations

        options = {:count=>2, :model=>"translation", :scope=>[:activerecord, :errors, :template]}
        @backend.translate("en", :"header", options).should == "2 errors prohibited this translation from being saved"
        @english_locale.should have(2).translations
      end

      it "should find lowest level translation" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
      
        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}
      
        @backend.translate("en", :"models.translation.attributes.locale.blank", options).should == "is blank moron!"
      end

      it "should find higher level translation" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'activerecord.errors.models.translation.blank', :value => 'translation blank')
      
        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}
      
        @backend.translate("en", :"models.translation.attributes.locale.blank", options).should == "translation blank"
      end

      it "should find highest level translation" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'activerecord.errors.models.translation.blank', :value => 'translation blank')
        @english_locale.translations.create!(:key => 'activerecord.errors.models.translation.attributes.locale.blank', :value => 'translation locale blank')
      
        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}
      
        @backend.translate("en", :"models.translation.attributes.locale.blank", options).should == "translation locale blank"
      end
      
      it "should find the translation for custom message" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'This is a custom message!', :value => 'This is a custom message!')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", "This is a custom message!", :"messages.blank"], :model=>"Translation"}

        @backend.translate("en", :"models.translation.attributes.locale.blank", options).should == "This is a custom message!"
      end

      it "should NOT find the translation for custom message" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'This is a custom message!', :value => 'This is a custom message!')
      
        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}
      
        @backend.translate("en", :"models.translation.attributes.locale.blank", options).should == "is blank moron!"
      end

    end

    describe "and locale es" do
      
      before(:each) do
        I18n.locale = "es"
        @spanish_locale = Locale.create!(:code => 'es')
      end
      
      it "should create a record with a nil value when the key is a string" do
        @backend.translate("es", "String")
        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == "String"
        @spanish_locale.translations.first.value.should be_nil
      end
      
      it "should return default locale (en) value and create the spanish record" do
        @english_locale.translations.create!(:key => 'String', :value => 'English String')
        @backend.translate("es", "String").should == "English String"
        @spanish_locale.should have(1).translation
      end
      
      it "should return just the passed in value when no translated record and no default translation" do
        @backend.translate("es", "String").should == "String" 
        @spanish_locale.should have(1).translation
      end

      it "should maybe have another test on interpolation"
      it "should be able to handle interpolated values" do
        options = {:count=>1, :model => ["Cheese"], :scope=>[:activerecord, :errors], :default=>["Locale"]}
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => '{{count}} error prohibited this {{model}} from being saved')
        @backend.translate("es", :"messages.blank", options).should == '1 error prohibited this Cheese from being saved'
      end

      it "should have some pluralization tests for both locales"

      it "should be able to handle pluralization" do
        @english_locale.translations.create!(:key => 'activerecord.errors.template.header', :value => '1 error prohibited this {{model}} from being saved', :pluralization_index => 1)
        @english_locale.translations.create!(:key => 'activerecord.errors.template.header', :value => '{{count}} errors prohibited this {{model}} from being saved', :pluralization_index => 0)
        options = {:count=>1, :model=>"translation", :scope=>[:activerecord, :errors, :template]}
        @backend.translate("es", :"header", options).should == "1 error prohibited this translation from being saved"
        @spanish_locale.should have(1).translations

        options = {:count=>2, :model=>"translation", :scope=>[:activerecord, :errors, :template]}
        @backend.translate("es", :"header", options).should == "2 errors prohibited this translation from being saved"
        @spanish_locale.should have(2).translations
      end

      
      it "should find lowest level translation" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
      
        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}
      
        @backend.translate("es", :"models.translation.attributes.locale.blank", options).should == "is blank moron!"
        
        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == "activerecord.errors.messages.blank"
        @spanish_locale.translations.first.value.should be_nil
      end

      it "should find higher level translation" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'activerecord.errors.models.translation.blank', :value => 'translation blank')
      
        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}
      
        @backend.translate("es", :"models.translation.attributes.locale.blank", options).should == "translation blank"
        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == "activerecord.errors.models.translation.blank"
        @spanish_locale.translations.first.value.should be_nil
      end

      it "should find highest level translation" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'activerecord.errors.models.translation.blank', :value => 'translation blank')
        @english_locale.translations.create!(:key => 'activerecord.errors.models.translation.attributes.locale.blank', :value => 'translation locale blank')
      
        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}
      
        @backend.translate("es", :"models.translation.attributes.locale.blank", options).should == "translation locale blank"
        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == "activerecord.errors.models.translation.attributes.locale.blank"
        @spanish_locale.translations.first.value.should be_nil
      end

      it "should find the translation for custom message" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'This is a custom message!', :value => 'This is a custom message!')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", "This is a custom message!", :"messages.blank"], :model=>"Translation"}

        @backend.translate("es", :"models.translation.attributes.locale.blank", options).should == "This is a custom message!"
        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == "This is a custom message!"
        @spanish_locale.translations.first.value.should be_nil
      end
      
    end

  end
  
  
end
