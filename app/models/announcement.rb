class Announcement
  include Mongoid::Document
  include Mongoid::Timestamps
  include Scram::DSL::ModelConditions
  include Concerns::Descriptable
  include Concerns::Escalatable

  after_create :alert_subscribers

  belongs_to :announceable, polymorphic: true
  belongs_to :poster, class_name: "User"

  validates_presence_of :name, :content

  scram_define do
    condition :collaborators do |announcement|
      if announcement.announceable.is_a? Concerns::Collaboratable
        announcement.announceable.send("*collaborators")
      else
        User.all.select{ |u| u.can?(:edit, announcement.announceable) }.map(&:scram_compare_value).to_a
      end
    end
  end

  class Alert < Subscription::Alert
      belongs_to :poster, class_name: 'User'
      belongs_to :announcement

      validates_presence_of :poster
      validates_presence_of :announcement

      delegate :link, to: :announcement

      def rich_message
        [{user: poster, message: " has posted an announcement in a #{announcement.announceable.class.to_s.humanize} you are subscribed to."}]
      end
  end

  def link
    announceable
  end

  def alert_subscribers
    if announceable.is_a? Concerns::Subscribable
      announceable.alert_subscribers(except: [poster], announcement: self, poster: poster)
    end
  end

end