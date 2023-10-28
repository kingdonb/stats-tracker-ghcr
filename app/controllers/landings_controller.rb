class LandingsController < ApplicationController
  before_action :set_landing, only: %i[ show edit update destroy ]
  before_action :authenticate_user!

  # GET /landings or /landings.json
  def index
    @landings = Landing.all
  end

  # GET /landings/1 or /landings/1.json
  def show
  end

  # GET /landings/new
  def new
    @landing = Landing.new
  end

  # GET /landings/1/edit
  def edit
  end

  # POST /landings or /landings.json
  def create
    @landing = Landing.new(landing_params)

    respond_to do |format|
      if @landing.save
        format.html { redirect_to landing_url(@landing), notice: "Landing was successfully created." }
        format.json { render :show, status: :created, location: @landing }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @landing.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /landings/1 or /landings/1.json
  def update
    respond_to do |format|
      if @landing.update(landing_params)
        format.html { redirect_to landing_url(@landing), notice: "Landing was successfully updated." }
        format.json { render :show, status: :ok, location: @landing }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @landing.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /landings/1 or /landings/1.json
  def destroy
    @landing.destroy

    respond_to do |format|
      format.html { redirect_to landings_url, notice: "Landing was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_landing
      @landing = Landing.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def landing_params
      params.require(:landing).permit(:email, :twitter, :fediverse, :accept_coc, :printed_stickers_already)
    end
end
