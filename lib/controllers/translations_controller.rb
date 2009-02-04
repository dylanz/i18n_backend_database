class TranslationsController < ActionController::Base
  prepend_view_path(File.join(File.dirname(__FILE__), "..", "views"))
  layout 'translations'
  before_filter :find_locale
  
  # GET /translations
  # GET /translations.xml
  def index
    @translations = @locale.translations.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @translations }
    end
  end

  # GET /untranslated
  # GET /untranslated.xml
  def untranslated
    @locale ||= Locale.default_locale
    @translations = @locale.translations.untranslated

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @translations }
    end
  end

  # GET /translations/1
  # GET /translations/1.xml
  def show
    @translation = @locale.translations.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @translation }
    end
  end

  # GET /translations/new
  # GET /translations/new.xml
  def new
    @translation = Translation.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @translation }
    end
  end

  # GET /translations/1/edit
  def edit
    @translation = @locale.translations.find(params[:id])
  end

  # POST /translations
  # POST /translations.xml
  def create
    @translation = @locale.translations.build(params[:translation])

    respond_to do |format|
      if @translation.save
        flash[:notice] = 'Translation was successfully created.'
        format.html { redirect_to locale_translation_path(@locale, @translation) }
        format.xml  { render :xml => @translation, :status => :created, :location => @translation }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @translation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /translations/1
  # PUT /translations/1.xml
  def update
    @translation = @locale.translations.find(params[:id])

    respond_to do |format|
      if @translation.update_attributes(params[:translation])
        flash[:notice] = 'Translation was successfully updated.'
        format.html { redirect_to locale_translation_path(@locale, @translation) }
        format.xml  { head :ok }
        format.js   {}
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @translation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /translations/1
  # DELETE /translations/1.xml
  def destroy
    @translation = @locale.translations.find(params[:id])
    @translation.destroy

    respond_to do |format|
      format.html { redirect_to(locale_translations_url) }
      format.xml  { head :ok }
    end
  end
  
  private
  
    def find_locale
      @locale = Locale.find_by_code(params[:locale_id])
    end
end
