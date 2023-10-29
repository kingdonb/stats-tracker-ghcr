class HistoriesController < ApplicationController
  before_action :set_history, only: %i[ show edit update destroy ]
  before_action :authenticate_user!

  # GET /histories or /histories.json
  def index
    @histories = History.all
  end

  # GET /histories/1 or /histories/1.json
  def show
  end

  # GET /histories/new
  def new
    @history = History.new
  end

  # GET /histories/1/edit
  def edit
  end

  # POST /histories or /histories.json
  def create
    @history = History.new(history_params)

    respond_to do |format|
      if @history.save
        format.html { redirect_to history_url(@history), notice: "History was successfully created." }
        format.json { render :show, status: :created, location: @history }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @history.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /histories/1 or /histories/1.json
  def update
    respond_to do |format|
      if @history.update(history_params)
        format.html { redirect_to history_url(@history), notice: "History was successfully updated." }
        format.json { render :show, status: :ok, location: @history }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @history.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /histories/1 or /histories/1.json
  def destroy
    @history.destroy

    respond_to do |format|
      format.html { redirect_to histories_url, notice: "History was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_history
      @history = History.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def history_params
      params.require(:history).permit(:sticker_id)
    end
end
