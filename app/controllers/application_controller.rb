class ApplicationController < ActionController::Base
  include ScramUtils
  helper_method :current_holder

  around_action :set_current_user

  protect_from_forgery with: :exception

  before_action :initialize_markdown
  before_action :find_alerts
  before_action :set_navbar_resources
  before_action :get_revision
  before_action :set_raven_context

  rescue_from ScramUtils::NotAuthorizedError do |exception|
    respond_to do |format|
      format.json { head :forbidden }
      format.html do
        unless user_signed_in?
          redirect_to main_app.new_user_session_path, :alert => "You must be signed in to do that."
        else
          redirect_to root_path, :alert => "You do not have permission to do that."
        end
      end
    end
  end

  def notify_integrations(message)
    Integration.each do |i|
      NotifyIntegrationJob.perform_later(i.id.to_s, message)
    end
  end

  rescue_from ActionController::RoutingError, :with => :not_found
  rescue_from Mongoid::Errors::DocumentNotFound, :with => :not_found

  def not_found
    redirect_to root_path, :alert => "The page you requested does not exist."
  end

  def peek_enabled?
    Rails.env.development? || (user_signed_in? && current_user.super_admin)
  end

  def autocomplete
    if params[:term]
      @users = User.any_of({name: /.*#{params[:term]}.*/i}, {email: /.*#{params[:term]}.*/i}).limit(5)
    else
      @users = User.all
    end

    respond_to do |format|
      format.json { render :json => @users.map{|u| {value: u.id.to_s, label: u.name, desc: u.email} }.to_json }
      end
  end

  protected
  def valid_user
    redirect_to new_user_session_path, :alert => 'You must be signed in to do this.' unless user_signed_in?
  end

  private

  def set_current_user
    Current.user = current_user
    yield
  ensure
    # to address the thread variable leak issues in Puma/Thin webserver
    Current.user = nil
  end

  def set_raven_context
    if current_user
      Raven.user_context(
        id: current_user.id.to_s,
        email: current_user.email,
        name: current_user.name
      )
    end

    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end

  def initialize_markdown
    @markdown = Redcarpet::Markdown.new(BootstrapRenderer.new(filter_html: true), tables: true)
  end

  def get_revision
    if defined? $g
      i = 0
      while $g.log[i].message =~ /\[HIDE\]/i or $g.log[i].message =~ /Merge ?:(pull request|branch) #(.*)/
        i += 1
      end
      @revision = $g.log[i].sha
    else
      @revision = ENV['GIT_SHA'] || "???"
    end
  end

  def set_navbar_resources
    @departments_summary = Rails.cache.fetch("nav_departments", expires_in: 5.minutes) do
      Department.by_priority.limit(6)
    end
    @active_closure = Closure.active_closure
  end

  def find_alerts
    if user_signed_in?
      q = current_user.alerts.unread.desc(:updated_at)
      @alerts = q.lazy.select(&:valid?).take(26).to_a

      if @alerts.size <= 25
        @alert_count = @alerts.size
      else
        @alerts = @alerts.take(25)
        @alert_count = q.count
      end
    end
  end
end
