class GithubOrgsController < ApplicationController
  before_action :set_github_org, only: %i[ show edit update destroy ]

  # GET /github_orgs or /github_orgs.json
  def index
    @github_orgs = GithubOrg.all
  end

  # GET /github_orgs/1 or /github_orgs/1.json
  def show
  end

  # GET /github_orgs/new
  def new
    @github_org = GithubOrg.new
  end

  # GET /github_orgs/1/edit
  def edit
  end

  # POST /github_orgs or /github_orgs.json
  def create
    @github_org = GithubOrg.new(github_org_params)

    respond_to do |format|
      if @github_org.save
        format.html { redirect_to github_org_url(@github_org), notice: "Github org was successfully created." }
        format.json { render :show, status: :created, location: @github_org }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @github_org.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /github_orgs/1 or /github_orgs/1.json
  def update
    respond_to do |format|
      if @github_org.update(github_org_params)
        format.html { redirect_to github_org_url(@github_org), notice: "Github org was successfully updated." }
        format.json { render :show, status: :ok, location: @github_org }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @github_org.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /github_orgs/1 or /github_orgs/1.json
  def destroy
    @github_org.destroy

    respond_to do |format|
      format.html { redirect_to github_orgs_url, notice: "Github org was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_github_org
      @github_org = GithubOrg.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def github_org_params
      params.require(:github_org).permit(:name)
    end
end
