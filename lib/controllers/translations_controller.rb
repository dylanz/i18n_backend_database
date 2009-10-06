class TranslationsController < ActionController::Base
  prepend_view_path(File.join(File.dirname(__FILE__), "..", "views"))
  layout 'translations'
  before_filter :find_locale
  
  # GET /translations
  # GET /translations.xml
  def index
    @translations = @locale.translations.find(:all, :order => "raw_key, pluralization_index")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @translations }
    end
  end

  # GET /translations
  # GET /translations.xml
  def translations
    @locale ||= Locale.default_locale
    @translation_option = TranslationOption.find(params[:translation_option])
    
    if @translation_option == TranslationOption.translated
      @translations = @locale.translations.translated
    else
      @translations = @locale.translations.untranslated
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @translations }
    end
  end

  # GET /asset_translations
  # GET /asset_translations.xml
  def asset_translations
    @locale ||= Locale.default_locale
    @translation_option = TranslationOption.find(params[:translation_option])

    @asset_translations  = I18n.asset_translations
    @untranslated_assets = I18n.untranslated_assets(@locale.code)
    @percentage_translated =   (((@asset_translations.size - @untranslated_assets.size).to_f / @asset_translations.size.to_f * 100).round) rescue 0

    if @translation_option == TranslationOption.translated
      @asset_translations = @asset_translations.reject{|e| @untranslated_assets.include?(e)}
    else
      @asset_translations = @untranslated_assets
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @untranslated_assets }
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
    @translation  = @locale.translations.find(params[:id])
    @first_time_translating = @translation.value.nil?

    respond_to do |format|
      if @translation.update_attributes(params[:translation])
        format.html do 
          flash[:notice] = 'Translation was successfully updated.'
          redirect_to locale_translation_path(@locale, @translation) 
        end
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
