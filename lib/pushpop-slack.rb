require 'pushpop'
require 'slack-notifier'

WEBHOOK_URL = ENV['SLACK_WEBHOOK_URL']

module Pushpop

  class Slack < Step

    PLUGIN_NAME = 'slack'

    Pushpop::Job.register_plugin(PLUGIN_NAME, self)

    attr_accessor :_channel
    attr_accessor :_username
    attr_accessor :_message
    attr_accessor :_icon
    attr_accessor :_icon_type
    attr_accessor :_attachments
    attr_accessor :_unfurl

    def run(last_response=nil, step_responses=nil)


      ret = configure(last_response, step_responses)

      if _message
        send_message
      else
        Pushpop.logger.debug("No slack message sent - message was not set")
      end

      clear_settings

      ret
    end

    def clear_settings
      self._username = nil
      self._message = nil
      self._icon = nil
      self._icon_type = nil
      self._attachments = nil
      self._unfurl = nil
    end

    def send_message
      unless WEBHOOK_URL.nil? || WEBHOOK_URL.empty?
        notifier = ::Slack::Notifier.new WEBHOOK_URL

        notifier.ping _message, options
      else
        Pushpop.logger.debug("Could not send slack message - SLACK_WEBHOOK_URL is nil or empty")
      end
    end

    def options
      opts = {}

      if _channel
        if _channel[0] == '#'
          opts['channel'] = _channel
        elsif _channel.present?
          opts['channel'] = "##{_channel}"
        end
      end

      if _username
        opts['username'] = _username
      end

      if _icon && _icon_type
        opts["icon_#{_icon_type}"] = _icon
      end

      if _attachments
        opts['attachments'] = _attachments
      end

      if _unfurl
        opts['unfurl_links'] = true
      end

      return opts
    end

    def channel(channel)
      self._channel = channel
    end

    def username(username)
      self._username = username
    end

    def message(message)
      self._message = ::Slack::Notifier::LinkFormatter.format(message)
    end

    def attachment(attachment)
      self._attachments = [] unless self._attachments

      self._attachments.push(attachment)
    end

    def icon(icon)
      if icon[0..3] == 'http'
        self._icon_type = 'url'
        self._icon = icon
      else
        self._icon_type = 'emoji'
        self._icon = icon

        # Make sure the emoji is wrapped in colons
        if self._icon[0] != ':'
          self._icon = ":#{self._icon}"
        end

        if self._icon[self._icon.length - 1] != ':'
          self._icon = "#{self._icon}:"
        end
      end

      self._icon
    end

    def unfurl(should = true)
      self._unfurl = should
    end

    def configure(last_response=nil, step_responses=nil)
      self.instance_exec(last_response, step_responses, &block)
    end

  end

end
