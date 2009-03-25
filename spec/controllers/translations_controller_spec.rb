require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TranslationsController do

  def mock_locale(stubs={})
    stubs = {
      :translations => mock("Array of Translations"),
      :to_param     => 'en'
    }.merge(stubs)
    
    @mock_locale ||= mock_model(Locale, stubs)
  end
  
  def mock_translation(stubs={})
    stubs = {
      :value => nil
    }.merge(stubs)
    @mock_translation ||= mock_model(Translation, stubs)
  end
  
  before(:each) do
    Locale.should_receive(:find_by_code).with('en').and_return(mock_locale)
  end
  
  describe "responding to GET index" do

    it "should expose all translations as @translations" do
      mock_locale.translations.should_receive(:find).with(:all, {:order=>"raw_key, pluralization_index"}).and_return([mock_translation])
      get :index, :locale_id => "en"
      assigns[:translations].should == [mock_translation]
    end

    describe "with mime type of xml" do
  
      it "should render all translations as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        mock_locale.translations.should_receive(:find).with(:all, {:order=>"raw_key, pluralization_index"}).and_return(translations = mock("Array of Translations"))
        translations.should_receive(:to_xml).and_return("generated XML")
        get :index, :locale_id => "en"
        response.body.should == "generated XML"
      end
    
    end

  end

  describe "responding to GET show" do

    it "should expose the requested translation as @translation" do
      mock_locale.translations.should_receive(:find).with("37").and_return(mock_translation)
      get :show, :locale_id => "en", :id => "37"
      assigns[:translation].should equal(mock_translation)
    end
    
    describe "with mime type of xml" do

      it "should render the requested translation as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        mock_locale.translations.should_receive(:find).with("37").and_return(mock_translation)
        mock_translation.should_receive(:to_xml).and_return("generated XML")
        get :show, :locale_id => "en", :id => "37"
        response.body.should == "generated XML"
      end

    end
    
  end

  describe "responding to GET new" do
  
    it "should expose a new translation as @translation" do
      Translation.should_receive(:new).and_return(mock_translation)
      get :new, :locale_id => "en"
      assigns[:translation].should equal(mock_translation)
    end

  end

  describe "responding to GET edit" do
  
    it "should expose the requested translation as @translation" do
      mock_locale.translations.should_receive(:find).with("37").and_return(mock_translation)
      get :edit, :locale_id => "en", :id => "37"
      assigns[:translation].should equal(mock_translation)
    end

  end

  describe "responding to POST create" do

    describe "with valid params" do
      
      it "should expose a newly created translation as @translation" do
        mock_locale.translations.should_receive(:build).with({'these' => 'params'}).and_return(mock_translation(:save => true))
        post :create, :locale_id => "en", :translation => {:these => 'params'}
        assigns(:translation).should equal(mock_translation)
      end

      it "should redirect to the created translation" do
        mock_locale.translations.stub!(:build).and_return(mock_translation(:save => true))
        post :create, :locale_id => "en", :translation => {}
        response.should redirect_to(locale_translation_url(mock_locale, mock_translation))
      end
      
    end
    
    describe "with invalid params" do

      it "should expose a newly created but unsaved translation as @translation" do
        mock_locale.translations.stub!(:build).with({'these' => 'params'}).and_return(mock_translation(:save => false))
        post :create, :locale_id => "en", :translation => {:these => 'params'}
        assigns(:translation).should equal(mock_translation)
      end

      it "should re-render the 'new' template" do
        mock_locale.translations.stub!(:build).and_return(mock_translation(:save => false))
        post :create, :locale_id => "en", :translation => {}
        response.should render_template('new')
      end
      
    end
    
  end

  describe "responding to PUT udpate" do

    describe "with valid params" do

      it "should update the requested translation" do
        mock_locale.translations.should_receive(:find).with("37").and_return(mock_translation)
        mock_translation.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :locale_id => "en", :id => "37", :translation => {:these => 'params'}
      end

      it "should expose the requested translation as @translation" do
        mock_locale.translations.stub!(:find).and_return(mock_translation(:update_attributes => true))
        put :update, :locale_id => "en", :id => "1"
        assigns(:translation).should equal(mock_translation)
      end

      it "should redirect to the translation" do
        mock_locale.translations.stub!(:find).and_return(mock_translation(:update_attributes => true))
        put :update, :locale_id => "en", :id => "1"
        response.should redirect_to(locale_translation_url(mock_locale, mock_translation))
      end

    end
    
    describe "with invalid params" do

      it "should update the requested translation" do
        mock_locale.translations.should_receive(:find).with("37").and_return(mock_translation)
        mock_translation.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :locale_id => "en", :id => "37", :translation => {:these => 'params'}
      end

      it "should expose the translation as @translation" do
        mock_locale.translations.stub!(:find).and_return(mock_translation(:update_attributes => false))
        put :update, :locale_id => "en", :id => "1"
        assigns(:translation).should equal(mock_translation)
      end

      it "should re-render the 'edit' template" do
        mock_locale.translations.stub!(:find).and_return(mock_translation(:update_attributes => false))
        put :update, :locale_id => "en", :id => "1"
        response.should render_template('edit')
      end

    end

  end

  describe "responding to DELETE destroy" do

    it "should destroy the requested translation" do
      mock_locale.translations.should_receive(:find).with("37").and_return(mock_translation)
      mock_translation.should_receive(:destroy)
      delete :destroy, :locale_id => "en", :id => "37"
    end
  
    it "should redirect to the translations list" do
      mock_locale.translations.stub!(:find).and_return(mock_translation(:destroy => true))
      delete :destroy, :locale_id => "en", :id => "1"
      response.should redirect_to(locale_translations_url(mock_locale))
    end

  end

end
