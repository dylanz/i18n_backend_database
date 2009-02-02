require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LocalesController do

  def mock_locale(stubs={})
    @mock_locale ||= mock_model(I18n::Locale, stubs)
  end
  
  describe "responding to GET index" do

    it "should expose all locales as @locales" do
      I18n::Locale.should_receive(:find).with(:all).and_return([mock_locale])
      get :index
      assigns[:locales].should == [mock_locale]
    end

    describe "with mime type of xml" do
  
      it "should render all locales as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        I18n::Locale.should_receive(:find).with(:all).and_return(locales = mock("Array of Locales"))
        locales.should_receive(:to_xml).and_return("generated XML")
        get :index
        response.body.should == "generated XML"
      end
    
    end

  end

  describe "responding to GET show" do

    it "should expose the requested locale as @locale" do
      I18n::Locale.should_receive(:find).with("37").and_return(mock_locale)
      get :show, :id => "37"
      assigns[:locale].should equal(mock_locale)
    end
    
    describe "with mime type of xml" do

      it "should render the requested locale as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        I18n::Locale.should_receive(:find).with("37").and_return(mock_locale)
        mock_locale.should_receive(:to_xml).and_return("generated XML")
        get :show, :id => "37"
        response.body.should == "generated XML"
      end

    end
    
  end

  describe "responding to GET new" do
  
    it "should expose a new locale as @locale" do
      I18n::Locale.should_receive(:new).and_return(mock_locale)
      get :new
      assigns[:locale].should equal(mock_locale)
    end

  end

  describe "responding to GET edit" do
  
    it "should expose the requested locale as @locale" do
      I18n::Locale.should_receive(:find).with("37").and_return(mock_locale)
      get :edit, :id => "37"
      assigns[:locale].should equal(mock_locale)
    end

  end

  describe "responding to POST create" do

    describe "with valid params" do
      
      it "should expose a newly created locale as @locale" do
        I18n::Locale.should_receive(:new).with({'these' => 'params'}).and_return(mock_locale(:save => true))
        post :create, :i18n_locale => {:these => 'params'}
        assigns(:locale).should equal(mock_locale)
      end

      it "should redirect to the created locale" do
        I18n::Locale.stub!(:new).and_return(mock_locale(:save => true))
        post :create, :locale => {}
        response.should redirect_to(i18n_locale_url(mock_locale))
      end
      
    end
    
    describe "with invalid params" do

      it "should expose a newly created but unsaved locale as @locale" do
        I18n::Locale.stub!(:new).with({'these' => 'params'}).and_return(mock_locale(:save => false))
        post :create, :i18n_locale => {:these => 'params'}
        assigns(:locale).should equal(mock_locale)
      end

      it "should re-render the 'new' template" do
        I18n::Locale.stub!(:new).and_return(mock_locale(:save => false))
        post :create, :locale => {}
        response.should render_template('new')
      end
      
    end
    
  end

  describe "responding to PUT udpate" do

    describe "with valid params" do

      it "should update the requested locale" do
        I18n::Locale.should_receive(:find).with("37").and_return(mock_locale)
        mock_locale.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :i18n_locale => {:these => 'params'}
      end

      it "should expose the requested locale as @locale" do
        I18n::Locale.stub!(:find).and_return(mock_locale(:update_attributes => true))
        put :update, :id => "1"
        assigns(:locale).should equal(mock_locale)
      end

      it "should redirect to the locale" do
        I18n::Locale.stub!(:find).and_return(mock_locale(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(i18n_locale_url(mock_locale))
      end

    end
    
    describe "with invalid params" do

      it "should update the requested locale" do
        I18n::Locale.should_receive(:find).with("37").and_return(mock_locale)
        mock_locale.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :i18n_locale => {:these => 'params'}
      end

      it "should expose the locale as @locale" do
        I18n::Locale.stub!(:find).and_return(mock_locale(:update_attributes => false))
        put :update, :id => "1"
        assigns(:locale).should equal(mock_locale)
      end

      it "should re-render the 'edit' template" do
        I18n::Locale.stub!(:find).and_return(mock_locale(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end

    end

  end

  describe "responding to DELETE destroy" do

    it "should destroy the requested locale" do
      I18n::Locale.should_receive(:find).with("37").and_return(mock_locale)
      mock_locale.should_receive(:destroy)
      delete :destroy, :id => "37"
    end
  
    it "should redirect to the locales list" do
      I18n::Locale.stub!(:find).and_return(mock_locale(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(i18n_locales_url)
    end

  end

end
