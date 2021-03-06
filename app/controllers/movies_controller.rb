class MoviesController < ApplicationController
  before_filter :get_movie, except: [:index, :new, :create]

  def index
    @movies = []
    order = case params[:order]
            when "date" then "data_files.created_at DESC"
            when "author" then "users.username ASC"
            when "ratings" then "total_ratings DESC"
            else "total_ratings DESC"
            end

    if params[:filter]
      Movie.index(order).each do |movie|
        if movie.file and movie.file.average_rating_round >= params[:filter].to_i
          @movies << movie
        end
      end
    else
      @movies = Movie.index(order)
    end
  end

  def show
    @movie.read_by! cuser if cuser
    @movie.record_view_count(request.remote_ip, cuser.nil?)
    redirect_to @movie.file.related if @movie.file and @movie.file.related
  end

  def refresh
    @movie.update_status
  end

  def new
    @movie = Movie.new
    raise AccessError unless @movie.can_create? cuser
  end

  def edit
    raise AccessError unless @movie.can_update? cuser
  end

  def create
    @movie = Movie.new(params[:movie])
    raise AccessError unless @movie.can_create? cuser

    if @movie.save
      flash[:notice] = t(:movies_create)
      redirect_to(@movie)
    else
      render :new
    end
  end

  def update
    raise AccessError unless @movie.can_update? cuser

    if @movie.update_attributes(params[:movie])
      flash[:notice] = t(:movies_update)
      redirect_to(@movie)
    else
      render :edit
    end
  end

  def preview
    raise AccessError unless @movie.can_update? cuser
    x = params[:x].to_i <= 1280 ? params[:x].to_i : 800
    y = params[:y].to_i <= 720 ? params[:y].to_i : 600
    render text: t(:executed) + "<br />" + @movie.make_preview(x, y), layout: true
  end

  def snapshot
    raise AccessError unless @movie.can_update? cuser
    secs = params[:secs].to_i > 0 ? params[:secs].to_i : 5
    render text: t(:executed) + "<br />" + @movie.make_snapshot(secs), layout: true
  end

  def download
    raise AccessError unless cuser.admin?
    @movie.stream_ip = params[:ip]
    @movie.stream_port = params[:port]
    render text: t(:executed) + "<br />" + @movie.make_stream, layout: true
  end

  def destroy
    raise AccessError unless @movie.can_destroy? cuser
    @movie.destroy
    redirect_to(movies_url)
  end

  private

  def get_movie
    @movie = Movie.find(params[:id])
  end
end
