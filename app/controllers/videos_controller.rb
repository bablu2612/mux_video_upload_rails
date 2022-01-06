class VideosController < ApplicationController
  before_action :set_video, only: %i[ show edit update destroy ]
  require 'open-uri'
 
  require 'uri'
  require 'net/http'
  require 'openssl'
  # GET /videos or /videos.json
  def index
    
    @videos = Video.all
  end

  # GET /videos/1 or /videos/1.json
  def show
  end

  # GET /videos/new
  def new
    @video = Video.new
  end

  # GET /videos/1/edit
  def edit
  end

  # POST /videos or /videos.json
  def create

    if video_params[:type] == 'mux'
    url_for_db,url,filename = mux_video_upload
    else
      access_token= get_acccess_token
      url_for_db,url,filename=create_video_api(access_token)
    end
   
    @video = Video.new(video_params)
    file = open(url)
    @video.main_image.attach(io: file, filename:filename)
    @video.video_url=url_for_db

    respond_to do |format|
      if @video.save
        format.html { redirect_to video_url(@video), notice: "Video was successfully created." }
        format.json { render :show, status: :created, location: @video }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @video.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /videos/1 or /videos/1.json
  def update
    respond_to do |format|
      if @video.update(video_params)
        format.html { redirect_to video_url(@video), notice: "Video was successfully updated." }
        format.json { render :show, status: :ok, location: @video }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @video.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /videos/1 or /videos/1.json
  def destroy
    @video.destroy

    respond_to do |format|
      format.html { redirect_to videos_url, notice: "Video was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_video
      @video = Video.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def video_params
      params.require(:video).permit(:title, :description, :video_url,:main_image,:type)
    end

    def get_acccess_token
      url = URI("https://sandbox.api.video/auth/api-key")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(url)
      request["Accept"] = 'application/json'
      request["Content-Type"] = 'application/json'
      request.body = "{\"apiKey\":\"AAI6qdUph27JUPBACgV4GeuQ7HQbOFrU4a1gfpXq9Cr\"}"
      
      response = http.request(request)
      access_token_data = eval(response.body)
      access_token= access_token_data[:access_token]
      access_token
    end

    def create_video_api(access_token)
      url = URI("https://sandbox.api.video/videos")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(url)
      request["Accept"] = 'application/json'
      request["Content-Type"] = 'application/json'
      request["Authorization"] = "Bearer #{access_token}"
      request.body = "{\"public\":true,\"panoramic\":false,\"mp4Support\":true,\"title\":\"#{video_params[:title]}\",\"description\":\"#{video_params[:description]}\",\"source\":\"#{video_params[:video_url].gsub("'", "")}\"}"
      
      response = http.request(request)
      create_video_data = eval(response.body)

      return create_video_data[:assets][:player],video_params[:video_url].gsub("'", ""),create_video_data[:videoId]
    end


    def mux_video_upload
      assets_api = MuxRuby::AssetsApi.new
      playback_ids_api = MuxRuby::PlaybackIDApi.new
      car = MuxRuby::CreateAssetRequest.new
      car.input = video_params[:video_url].gsub("'", "")
      car.mp4_support= "standard"
      create_response = assets_api.create_asset(car)
      
      cpbr = MuxRuby::CreatePlaybackIDRequest.new
      cpbr.policy = MuxRuby::PlaybackPolicy::PUBLIC
      pb_id_c = assets_api.create_asset_playback_id(create_response.data.id, cpbr)
      
      url_for_db= "https://stream.mux.com/#{pb_id_c.data.id}/low.mp4"
      url= video_params[:video_url].gsub("'", "")

      return url_for_db,url,pb_id_c.data.id

    end
end
