require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LocalesController do
  describe "route generation" do
    it "should map #index" do
      route_for(:controller => "locales", :action => "index").should == "/locales"
    end
  
    it "should map #new" do
      route_for(:controller => "locales", :action => "new").should == "/locales/new"
    end
  
    it "should map #show" do
      route_for(:controller => "locales", :action => "show", :id => 1).should == "/locales/1"
    end
  
    it "should map #edit" do
      route_for(:controller => "locales", :action => "edit", :id => 1).should == "/locales/1/edit"
    end
  
    it "should map #update" do
      route_for(:controller => "locales", :action => "update", :id => 1).should == "/locales/1"
    end
  
    it "should map #destroy" do
      route_for(:controller => "locales", :action => "destroy", :id => 1).should == "/locales/1"
    end
  end

  describe "route recognition" do
    it "should generate params for #index" do
      params_from(:get, "/locales").should == {:controller => "locales", :action => "index"}
    end
  
    it "should generate params for #new" do
      params_from(:get, "/locales/new").should == {:controller => "locales", :action => "new"}
    end
  
    it "should generate params for #create" do
      params_from(:post, "/locales").should == {:controller => "locales", :action => "create"}
    end
  
    it "should generate params for #show" do
      params_from(:get, "/locales/1").should == {:controller => "locales", :action => "show", :id => "1"}
    end
  
    it "should generate params for #edit" do
      params_from(:get, "/locales/1/edit").should == {:controller => "locales", :action => "edit", :id => "1"}
    end
  
    it "should generate params for #update" do
      params_from(:put, "/locales/1").should == {:controller => "locales", :action => "update", :id => "1"}
    end
  
    it "should generate params for #destroy" do
      params_from(:delete, "/locales/1").should == {:controller => "locales", :action => "destroy", :id => "1"}
    end
  end
end
