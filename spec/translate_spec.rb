require File.dirname(__FILE__) + '/spec_helper'

class MemoryStoreProxy < ActiveSupport::Cache::MemoryStore
  attr_accessor :write_count

  def initialize
    @write_count = 0
    super
  end

  def write(key, value, options = nil)
    super(key, value, options)
    @write_count += 1
  end
end

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

      it "should create a record with the key as the value when the key is a string" do
        @backend.translate("en", "String").should == "String"
        @english_locale.should have(1).translation
        @english_locale.translations.first.key.should == Translation.hk("String")
        @english_locale.translations.first.raw_key.should == "String"
        @english_locale.translations.first.value.should == "String"
      end

      it "should not write to the cache if the key already exists in the cache" do
        @backend.cache_store = MemoryStoreProxy.new
        @english_locale.translations.create!(:key => 'String', :value => 'Value')

        @backend.translate("en", "String").should == "Value"
        @backend.cache_store.write_count.should == 1

        @backend.translate("en", "String").should == "Value"
        @backend.cache_store.write_count.should == 1
      end

      it "should create a record with the key as the value when the key is a string and cache that record" do
        @backend.translate("en", "status").should == "status"
        @english_locale.should have(1).translation

        # once cached
        @backend.translate("en", "status").should == "status"
        @english_locale.should have(1).translation
      end

      it "should find a record with the key as the value when the key is a string" do
        @english_locale.translations.create!(:key => 'String', :value => 'Value')
        @backend.translate("en", "String").should == "Value"
        @english_locale.should have(1).translation
      end

      it "should support having a record with a nil value" do
        @english_locale.translations.create!(:key => 'date.order')
        @backend.translate("en", :'date.order').should be_nil
        @english_locale.should have(1).translation
      end

      it "should create a record with a nil value when key is a symbol" do
        @backend.translate("en", :'date.order').should be_nil
        @english_locale.should have(1).translation
        @english_locale.translations.first.key.should == Translation.hk('date.order')
        @english_locale.translations.first.raw_key.should == "date.order"
        @english_locale.translations.first.value.should be_nil

        # once cached
        @backend.translate("en", :'date.order').should be_nil
        @english_locale.reload.should have(1).translation
      end

      it "should support storing values as YAML symbols" do
        @english_locale.translations.create!(:key => 'date.order', :value => "--- :year\n",  :pluralization_index => 0)
        @english_locale.translations.create!(:key => 'date.order', :value => "--- :month\n", :pluralization_index => 1)
        @english_locale.translations.create!(:key => 'date.order', :value => "--- :day\n",   :pluralization_index => 2)

        @backend.translate("en", :'date.order').should == [:year, :month, :day]
        @english_locale.should have(3).translations
      end

      it "should find a cached record from a cache key if it exists in the cache" do
        hash_key = Translation.hk("blah")
        @backend.cache_store.write("en:#{hash_key}", 'woot')
        @backend.translate("en", "blah").should == "woot"
      end

      it "should find a cached record with a nil value from a cache key if it exists in the cache" do
        hash_key = Translation.hk(".date.order")
        @backend.cache_store.write("en:#{hash_key}", nil)
        @backend.translate("en", :'date.order').should be_nil
      end

      it "should write a cache record to the cache for a newly created translation record" do
        hash_key = Translation.hk("blah")
        @backend.translate("en", "blah")
        @backend.cache_store.read("en:#{hash_key}").should == "blah"
      end

      it "should write a cache record to the cache for translation record with nil value" do
        @english_locale.translations.create!(:key => '.date.order')
        @backend.translate("en", :'date.order').should be_nil

        hash_key = Translation.hk(".date.order")
        @backend.cache_store.read("en:#{hash_key}").should be_nil
      end

      it "should handle active record helper defaults, where default is the object name" do
        options = {:count=>1, :scope=>[:activerecord, :models], :default=>"post"}
        @english_locale.translations.create!(:key => 'activerecord.errors.models.blank', :value => 'post')
        @backend.translate("en", :"models.blank", options).should == 'post'
      end

      it "should handle translating defaults used by active record attributes" do
        options = {:scope=>[:activerecord, :attributes], :count=>1, :default=>["Content"]}
        @backend.translate("en", :"post.content", options).should == 'Content'

        # and when cached
        options = {:scope=>[:activerecord, :attributes], :count=>1, :default=>["Content"]}
        @backend.translate("en", :"post.content", options).should == 'Content'
        @english_locale.should have(1).translation
      end

      it "should be able to handle interpolated values" do
        options = {:some_value => 'INTERPOLATED'}
        @english_locale.translations.create!(:key => 'Fred', :value => 'Fred has been {{some_value}}!!')
        @backend.translate("en", 'Fred', options).should == 'Fred has been INTERPOLATED!!'
      end

      it "should be able to handle interpolated values with 'Fred {{some_value}}' also as the key" do
        options = {:some_value => 'INTERPOLATED'}
        @english_locale.translations.create!(:key => 'Fred {{some_value}}', :value => 'Fred {{some_value}}!!')
        @backend.translate("en", 'Fred {{some_value}}', options).should == 'Fred INTERPOLATED!!'
      end

      it "should be able to handle interpolated count values" do
        options = {:count=>1, :model => ["Cheese"], :scope=>[:activerecord, :errors], :default=>["Locale"]}
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => '{{count}} errors prohibited this {{model}} from being saved')
        @backend.translate("en", :"messages.blank", options).should == '1 errors prohibited this Cheese from being saved'
      end

      it "should be able to handle the case of scope being passed in as something other than an array" do
        options = {:count=>1, :model => ["Cheese"], :scope=> :activerecord, :default=>["Locale"]}
        @english_locale.translations.create!(:key => 'activerecord.messages.blank', :value => 'dude')
        @backend.translate("en", :"messages.blank", options).should == 'dude'
      end

      it "should be able to handle pluralization" do
        @english_locale.translations.create!(:key => 'activerecord.errors.template.header', :value => '1 error prohibited this {{model}} from being saved', :pluralization_index => 1)
        @english_locale.translations.create!(:key => 'activerecord.errors.template.header', :value => '{{count}} errors prohibited this {{model}} from being saved', :pluralization_index => 0)

        options = {:count=>1, :model=>"translation", :scope=>[:activerecord, :errors, :template]}
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

      it "should create the translation for custom message" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", "This is a custom message!", :"messages.blank"], :model=>"Translation"}

        @backend.translate("en", :"models.translation.attributes.locale.blank", options).should == "This is a custom message!"
        @english_locale.should have(2).translations
        @english_locale.translations.find_by_key(Translation.hk("This is a custom message!")).value.should == 'This is a custom message!'
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

      it "should return an array" do
        @english_locale.translations.create!(:key => 'date.month_names', :value => 'January',  :pluralization_index => 1)
        @english_locale.translations.create!(:key => 'date.month_names', :value => 'February', :pluralization_index => 2)
        @english_locale.translations.create!(:key => 'date.month_names', :value => 'March',    :pluralization_index => 3)
        @backend.translate("en", :"date.month_names").should == [nil, 'January', 'February', 'March']

        # once cached
        @backend.translate("en", :"date.month_names").should == [nil, 'January', 'February', 'March']
        @english_locale.reload.should have(3).translation
      end

      it "should return an unfrozen array" do
        @english_locale.translations.create!(:key => 'date.month_names', :value => 'January',  :pluralization_index => 1)
        @english_locale.translations.create!(:key => 'date.month_names', :value => 'February', :pluralization_index => 2)
        @english_locale.translations.create!(:key => 'date.month_names', :value => 'March',    :pluralization_index => 3)
        @backend.translate("en", :"date.month_names").should_not be_frozen

        # once cached
        @backend.translate("en", :"date.month_names").should_not be_frozen
      end

      it "should return an array of days" do
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Sunday',    :pluralization_index => 0)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Monday',    :pluralization_index => 1)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Tuesday',   :pluralization_index => 2)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Wednesday', :pluralization_index => 3)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Thursday',  :pluralization_index => 4)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Friday',    :pluralization_index => 5)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Saturday',  :pluralization_index => 6)

        # once cached
        @backend.translate("en", :"date.day_names").should == ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
        @english_locale.reload.should have(7).translation
      end

    end

    describe "and locale es" do
      before(:each) do
        I18n.locale = "es"
        @spanish_locale = Locale.create!(:code => 'es')
      end

      it "should create a record with a nil value when the key is a string" do
        @backend.translate("es", "String").should == "String"
        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == Translation.hk("String")
        @spanish_locale.translations.first.value.should be_nil
      end

      it "should not write to the cache if the key already exists in the cache" do
        @backend.cache_store = MemoryStoreProxy.new
        @english_locale.translations.create!(:key => 'Message Center', :value => 'Message Center')
        @spanish_locale.translations.create!(:key => 'Message Center', :value => nil)

        @backend.translate("es", "Message Center").should == "Message Center"
        @backend.cache_store.write_count.should == 1

        @backend.translate("es", "Message Center").should == "Message Center"
        @backend.cache_store.write_count.should == 1
      end

      it "should handle basic workflow" do
        @english_locale.translations.create!(:key => 'Message Center', :value => 'Message Center')
        @spanish_locale.translations.create!(:key => 'Message Center', :value => nil)

        @backend.translate("en", "Message Center").should == "Message Center"

        @english_locale.should have(1).translation
        @english_locale.translations.first.key.should == Translation.hk("Message Center")
        @english_locale.translations.first.raw_key.should == "Message Center"
        @english_locale.translations.first.value.should == "Message Center"

        @backend.translate("es", "Message Center").should == "Message Center"

        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == Translation.hk("Message Center")
        @spanish_locale.translations.first.value.should be_nil
        
        @backend.translate("es", "Message Center").should == "Message Center"
        @spanish_locale.should have(1).translation
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

      it "should support having a default locale record with a nil value" do
        @english_locale.translations.create!(:key => 'date.order')
        @backend.translate("es", :'date.order').should be_nil

        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == Translation.hk('date.order')
        @spanish_locale.translations.first.value.should be_nil
      end

      it "should be able to handle interpolated values" do
        options = {:some_value => 'INTERPOLATED'}
        @english_locale.translations.create!(:key => 'Fred', :value => 'Fred has been {{some_value}}!!')
        @spanish_locale.translations.create!(:key => 'Fred', :value => 'Fred ha sido {{some_value}}!!')
        @backend.translate("es", 'Fred', options).should == 'Fred ha sido INTERPOLATED!!'
      end

      it "should be able to handle interpolated count values" do
        options = {:count=>1, :model => ["Cheese"], :scope=>[:activerecord, :errors], :default=>["Locale"]}
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => '{{count}} error prohibited this {{model}} from being saved')
        @backend.translate("es", :"messages.blank", options).should == '1 error prohibited this Cheese from being saved'
      end

      it "should be able to handle pluralization" do
        @english_locale.translations.create!(:key => 'activerecord.errors.template.header', :value => '1 error prohibited this {{model}} from being saved', :pluralization_index => 1)
        @english_locale.translations.create!(:key => 'activerecord.errors.template.header', :value => '{{count}} errors prohibited this {{model}} from being saved', :pluralization_index => 0)
        options = {:count=>1, :model=>"translation", :scope=>[:activerecord, :errors, :template]}
        @backend.translate("es", :"header", options).should == "1 error prohibited this translation from being saved"
        @spanish_locale.should have(2).translations

        options = {:count=>2, :model=>"translation", :scope=>[:activerecord, :errors, :template]}
        @backend.translate("es", :"header", options).should == "2 errors prohibited this translation from being saved"
        @spanish_locale.reload.should have(2).translations
      end

      it "should find lowest level translation" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}

        @backend.translate("es", :"models.translation.attributes.locale.blank", options).should == "is blank moron!"

        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == Translation.hk("activerecord.errors.messages.blank")
        @spanish_locale.translations.first.value.should be_nil
      end

      it "should find higher level translation" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'activerecord.errors.models.translation.blank', :value => 'translation blank')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}

        @backend.translate("es", :"models.translation.attributes.locale.blank", options).should == "translation blank"
        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == Translation.hk("activerecord.errors.models.translation.blank")
        @spanish_locale.translations.first.value.should be_nil
        @backend.cache_store.read("es:activerecord.errors.models.translation.blank", "translation blank")
      end

      it "should find highest level translation" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'activerecord.errors.models.translation.blank', :value => 'translation blank')
        @english_locale.translations.create!(:key => 'activerecord.errors.models.translation.attributes.locale.blank', :value => 'translation locale blank')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}

        @backend.translate("es", :"models.translation.attributes.locale.blank", options).should == "translation locale blank"
        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == Translation.hk("activerecord.errors.models.translation.attributes.locale.blank")
        @spanish_locale.translations.first.value.should be_nil
      end

      it "should find the translation for custom message" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'This is a custom message!', :value => 'This is a custom message!')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", "This is a custom message!", :"messages.blank"], :model=>"Translation"}

        @backend.translate("es", :"models.translation.attributes.locale.blank", options).should == "This is a custom message!"
        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == Translation.hk("This is a custom message!")
        @spanish_locale.translations.first.value.should be_nil
      end

      it "should return an array from spanish locale" do
        @english_locale.translations.create!(:key => 'date.month_names', :value => 'January',  :pluralization_index => 1)
        @english_locale.translations.create!(:key => 'date.month_names', :value => 'February', :pluralization_index => 2)
        @english_locale.translations.create!(:key => 'date.month_names', :value => 'March',    :pluralization_index => 3)
        @spanish_locale.translations.create!(:key => 'date.month_names', :value => 'Enero',    :pluralization_index => 1)
        @spanish_locale.translations.create!(:key => 'date.month_names', :value => 'Febrero',  :pluralization_index => 2)
        @spanish_locale.translations.create!(:key => 'date.month_names', :value => 'Marzo',    :pluralization_index => 3)

        @backend.translate("es", :"date.month_names").should == [nil, 'Enero', 'Febrero', 'Marzo']

        # once cached
        @backend.translate("es", :"date.month_names").should == [nil, 'Enero', 'Febrero', 'Marzo']
        @english_locale.reload.should have(3).translation
        @spanish_locale.reload.should have(3).translation
      end

      it "should return an array from default locale" do
        @english_locale.translations.create!(:key => 'date.month_names', :value => 'January',  :pluralization_index => 1)
        @english_locale.translations.create!(:key => 'date.month_names', :value => 'February', :pluralization_index => 2)
        @english_locale.translations.create!(:key => 'date.month_names', :value => 'March',    :pluralization_index => 3)
        @backend.translate("es", :"date.month_names").should == [nil, 'January', 'February', 'March']

        # once cached
        @backend.translate("es", :"date.month_names").should == [nil, 'January', 'February', 'March']
        @english_locale.reload.should have(3).translation
        @spanish_locale.reload.should have(3).translation
      end

      it "should return an array of days" do
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Sunday',    :pluralization_index => 0)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Monday',    :pluralization_index => 1)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Tuesday',   :pluralization_index => 2)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Wednesday', :pluralization_index => 3)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Thursday',  :pluralization_index => 4)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Friday',    :pluralization_index => 5)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Saturday',  :pluralization_index => 6)
        @backend.translate("es", :"date.day_names").should == ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']

        # once cached
        @backend.translate("es", :"date.day_names").should == ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
        @english_locale.reload.should have(7).translation
        @spanish_locale.reload.should have(7).translation
      end

      it "should return an array of days" do
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Sunday',    :pluralization_index => 0)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Monday',    :pluralization_index => 1)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Tuesday',   :pluralization_index => 2)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Wednesday', :pluralization_index => 3)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Thursday',  :pluralization_index => 4)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Friday',    :pluralization_index => 5)
        @english_locale.translations.create!(:key => 'date.day_names', :value => 'Saturday',  :pluralization_index => 6)
        @spanish_locale.translations.create!(:key => 'date.day_names', :value => nil,         :pluralization_index => 0)
        @spanish_locale.translations.create!(:key => 'date.day_names', :value => nil,         :pluralization_index => 1)
        @spanish_locale.translations.create!(:key => 'date.day_names', :value => nil,         :pluralization_index => 2)
        @spanish_locale.translations.create!(:key => 'date.day_names', :value => nil,         :pluralization_index => 3)
        @spanish_locale.translations.create!(:key => 'date.day_names', :value => nil,         :pluralization_index => 4)
        @spanish_locale.translations.create!(:key => 'date.day_names', :value => nil,         :pluralization_index => 5)
        @spanish_locale.translations.create!(:key => 'date.day_names', :value => nil,         :pluralization_index => 6)
        @backend.translate("es", :"date.day_names").should == ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']

        # once cached
        @backend.translate("es", :"date.day_names").should == ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
        @english_locale.reload.should have(7).translation
        @spanish_locale.reload.should have(7).translation
      end

      it "should support storing values as YAML symbols" do
        @english_locale.translations.create!(:key => 'date.order', :value => "--- :year\n",  :pluralization_index => 0)
        @english_locale.translations.create!(:key => 'date.order', :value => "--- :month\n", :pluralization_index => 1)
        @english_locale.translations.create!(:key => 'date.order', :value => "--- :day\n",   :pluralization_index => 2)

        @backend.translate("es", :'date.order').should == [:year, :month, :day]
        @english_locale.should have(3).translations
        @spanish_locale.should have(3).translations
      end

    end
  end
end
