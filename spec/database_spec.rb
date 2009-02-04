require File.dirname(__FILE__) + '/spec_helper'

describe I18n::Backend::Database do
  describe "an instance" do
    before {
      I18n.locale = "es"
      @locales    = [:en, :es, :it]
      @locale     = mock_model(Locale, { :code => "es" })
      Locale.stub!(:available_locales).and_return(@locales)
      Locale.stub!(:find_by_code).and_return(@locale)
      @database   = I18n::Backend::Database.new
    }

    it "should use the current Rails cache store if none are provided" do
      @database.cache_store.should == Rails.cache
    end

    it "should use a custom cache store if provided" do
      @database = I18n::Backend::Database.new({:cache_store => :mem_cache_store})
      @database.cache_store.class.should == ActiveSupport::Cache::MemCacheStore
    end

    it "should delegate the call to available_locales to the Locale class" do
      Locale.should_receive(:available_locales)
      @database.available_locales
    end

    it "should return all the available locales on a call to available_locales" do
      @database.available_locales.should == @locales
    end

    it "should return a cache key of locale:key on call to build_cache_key" do
      @database.send(:build_cache_key, @locale, "hola me amigo!").should == "es:hola me amigo!"
    end

    it "should generate a Base64 encoded, MD5 encrypted hash, based on the key" do
      encrypted_key = Digest::MD5.hexdigest("aoeuaoeu")
      completed_key = @database.send(:generate_hash_key, "aoeuaoeu")
      encrypted_key.should == Base64.decode64(completed_key)
    end

    it "should have a nil locale cache by default" do
      @database.locale.should == nil
    end

    it "should be able to set the locale cache by passing a locale code into locale=" do
      @database.locale = "es"
      @database.locale.should == @locale
    end
  end

  describe "translating a key" do
    it "should have specs outlining the results of all the translation possibilities"

    describe "for the first time in the default locale" do
    end

    describe "for the first time in an alternate locale" do
    end

    describe "for the subsequent call in the default locale" do
    end

    describe "for the subsequent call in the alternate locale" do
    end
  end

  describe "setting a locale in context" do
    before {
      I18n.locale = "es"
      @locale     = mock_model(Locale, { :code => "es" })
      @database   = I18n::Backend::Database.new
    }

    describe "on a new instance when the cache locale is nil" do
      before {
        Locale.stub!(:find_by_code).and_return(@locale)
      }

      it "should return a locale record for the current locale in context" do
        Locale.should_receive(:find_by_code).with(I18n.locale)
        @database.send(:locale_in_context)
      end
    end

    describe "when passing in a temporary locale that's different from the local cache" do
      before {
        Locale.stub!(:find_by_code).with("it").and_return(@locale)
        @database.locale = "it"
      }

      it "should return a locale record for the temporary locale" do
        Locale.should_receive(:find_by_code).with("it")
        @database.send(:locale_in_context, "it")
      end

      it "should set the locale to the temporary value" do
        @database.send(:locale_in_context, "it").should == @locale
      end
    end

    describe "when passing in a temporary locale that's the same as the local cache" do
      before {
        Locale.stub!(:find_by_code).with("es").and_return(@locale)
        @database.locale = "es"
      }

      it "should set the locale to the temporary value" do
        @database.send(:locale_in_context, "es").should == @locale
      end
    end

    describe "when the locale is the same as the cache" do
      before {
        Locale.stub!(:find_by_code).with("es").and_return(@locale)
      }

      it "should update the locale cache with the new locale" do
        @database.locale = "es"
        @database.send(:locale_in_context).should == @database.locale
      end
    end

    describe "when the locale is different than the cache" do
      before {
        Locale.stub!(:find_by_code).with("es").and_return(@locale)
        I18n.locale = "it"
      }

      it "should update the locale cache with the new locale" do
        @database.locale = "es"
        Locale.should_receive(:find_by_code).with("it")
        @database.send(:locale_in_context)
      end
    end
  end
end
