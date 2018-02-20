class WelcomeController < ApplicationController
  before_action :get_information, only: %i[index landing]

  def index
    @active_promotions = Rails.cache.fetch('active_promotions', expires_in: 5.minutes) do
      Promotion.where(enabled: true).by_priority
    end
  end

  def about; end

  def landing
    expires_in 5.minutes, public: true unless Current.user
  end

  def status
    render json: { ok: true }
  end

  private

  def get_information
    @announcements = Rails.cache.fetch('announcements', expires_in: 5.minutes) do
      # First 8 escalated announcements, padded with latest if there are less than 8
      (Announcement.escalated(8).sort_by!(&:created_at).reverse + Announcement.desc(:created_at).limit(8).to_a)
        .first(8).uniq
    end
    @links = Rails.cache.fetch('links', expires_in: 5.minutes) do
      Link.escalated(5).sort_by!(&:created_at)
    end
  end
end
