require File.dirname(__FILE__) + '/spec_helper'

describe I18n do

  describe "with default locale en" do
    before(:each) do
      I18n.default_locale = "en"
    end

    describe "and locale en" do
      before(:each) do
        I18n.locale = "en"
      end

      it "should return empty local segment" do
        I18n.locale_segment.should == ''
      end

      it "should return empty local segment using alias" do
        I18n.ls.should == ''
      end
    end

    describe "and locale es" do
      before(:each) do
        I18n.locale = "es"
      end

      it "should return es local segment" do
        I18n.locale_segment.should == '/es'
      end

      it "should return es local segment using alias" do
        I18n.ls.should == '/es'
      end
    end

  end

end
