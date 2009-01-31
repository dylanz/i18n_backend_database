require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + '/../lib/i18n_backend_database/locale'
require File.dirname(__FILE__) + '/../lib/i18n_backend_database/translation'

describe I18n::Backend::Database do
  before {
    I18n.locale = "es"
    @locales    = [:en, :es, :it]
    @locale     = mock_model(I18n::Backend::Database::Locale, { :code => "es" })
    I18n::Backend::Database::Locale.stub!(:available_locales).and_return(@locales)
    I18n::Backend::Database::Locale.stub!(:find_by_code).and_return(@locale)
    @database   = I18n::Backend::Database.new
  }

  describe "an instance" do
    it "should use the current Rails cache store if none are provided" do
      @database.cache_store.should == Rails.cache
    end

    it "should use a custom cache store if provided" do
      @database = I18n::Backend::Database.new({:cache_store => :mem_cache_store})
      @database.cache_store.class.should == ActiveSupport::Cache::MemCacheStore
    end

    it "should have a handle to a Locale instance of the current threads locale" do
      @database.locale.code.should == I18n.locale.to_s
    end

    it "should delegate the call to available_locales to the Locale class" do
      I18n::Backend::Database::Locale.should_receive(:available_locales)
      @database.available_locales
    end

    it "should return all the available locales on a call to available_locales" do
      @database.available_locales.should == @locales
    end

    it "should return a cache key of locale:key:pluralization on call to build_cache_key" do
      @database.send(:build_cache_key, @locale, "hola me amigo!", :pluralization_index => 1).should == "es:hola me amigo!:1"
    end
  end

  describe "translating" do
    before {
      @locale   = mock_model(I18n::Backend::Database::Locale, { :code => "es" })
      I18n::Backend::Database::Locale.stub!(:find_by_code).and_return(@locale)
      @database = I18n::Backend::Database.new({:cache_store => :memory_store})
    }

    after { @database.cache_store.clear }

    it "should return the value from the cache if available" do
      @database.cache_store.write("es:hello:1", "hola")
      @database.translate(@locale.code, "hello").should == "hola"
    end
  end
end
