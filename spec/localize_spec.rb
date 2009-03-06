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
      # load database with default active_support translations for english locale
      I18nUtil.load_from_yml 'vendor/rails/activesupport/lib/active_support/locale/en.yml' 
    end

    describe "and locale en" do
      before(:each) do
        I18n.locale = "en"
      end

      it "should localize dates in different formats" do
        dates = {
          Date.new(2009,1,1)   => {:default => "2009-01-01", :short => "Jan 01", :long => "January 01, 2009"},
          Date.new(2009,1,31)  => {:default => "2009-01-31", :short => "Jan 31", :long => "January 31, 2009"},
          Date.new(2009,2,2)   => {:default => "2009-02-02", :short => "Feb 02", :long => "February 02, 2009"},
          Date.new(2009,2,28)  => {:default => "2009-02-28", :short => "Feb 28", :long => "February 28, 2009"},
          Date.new(2008,2,29)  => {:default => "2008-02-29", :short => "Feb 29", :long => "February 29, 2008"},
          Date.new(2009,3,11)  => {:default => "2009-03-11", :short => "Mar 11", :long => "March 11, 2009"},
          Date.new(2010,4,30)  => {:default => "2010-04-30", :short => "Apr 30", :long => "April 30, 2010"},
          Date.new(2020,12,31) => {:default => "2020-12-31", :short => "Dec 31", :long => "December 31, 2020"}
        }  

        dates.each do |date, formats|
          formats.each do |format, expected_value|
            @backend.localize("en", date, format).should == expected_value
          end
        end
      end

      it "should localize times in different formats" do
        time = DateTime.new(y=2008,m=3,d=22,h=16,min=30,s=12)

        @backend.localize("en", time, :default).should == "Sat, 22 Mar 2008 16:30:12 +0000"
        @backend.localize("en", time, :short).should == "22 Mar 16:30"
        @backend.localize("en", time, :long).should == "March 22, 2008 16:30"
        @backend.localize("en", time, '%B %d, %Y %H:%M %p').should == "March 22, 2008 16:30 pm"
      end

    end

    describe "and locale es" do
      before(:each) do
        I18n.locale = "es"
        @spanish_locale = Locale.create!(:code => 'es')
      end

    end
  end
end
