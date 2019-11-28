module RedmineEmailInlineImages

  module MailHandlerPatch

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        alias_method :email_parts_to_text_default, :email_parts_to_text
        alias_method :email_parts_to_text, :email_parts_to_text_with_inline_images

        alias_method :add_attachments_default, :add_attachments
        alias_method :add_attachments, :add_attachments_with_inline_images
      end
    end


    module InstanceMethods
      private
      @images
      @strOpen
      @strClose

      def initialize
        @images = {}
        case Setting.text_formatting
        when 'markdown'
          @strOpen = "![]("
          @strClose = ")"
        when 'textile'
          @strOpen = "!"
          @strClose = "!"
        else
          @strOpen = ""
          @strClose = ""
        end
      end

      # Overrides the email_parts_to_text method to
      # include inline images from an email for
      # an issue created by an email request
      def email_parts_to_text_with_inline_images(parts)
  
        email.all_parts.each do |part|
            if part['Content-ID']
                if part['Content-ID'].respond_to?(:element)
                    content_id = part['Content-ID'].element.message_ids[0]
                else
                    content_id = part['Content-ID'].value.gsub(%r{(^<|>$)}, '')
                end
                image = part.header['Content-Type'].parameters['name']
                @images["cid:#{content_id}"] = image
            end
        end

        parts.reject! do |part|
          part.attachment?
        end
    
        parts.map do |part|
          body_charset = Mail::RubyVer.respond_to?(:pick_encoding) ?
                          Mail::RubyVer.pick_encoding(part.charset).to_s : part.charset
    
          body = Redmine::CodesetUtil.to_utf8(part.body.decoded, body_charset)

          # replace html images with text bang notation
          # and add them to Hash
          body.scan(/(\[(cid:.*?)\])/).each do |match|
            tmp_body = body.gsub(match[0], "#{@strOpen}#{@images[match[1]]}#{@strClose}")
            body = tmp_body
          end

          # convert html parts to text
          part.mime_type == 'text/html' ? self.class.html_body_to_text(body) : self.class.plain_text_body_to_text(body)
        end.join("\r\n")

      end

      # update issue inline images with full path
      # to prevent overlapping names when replies come in
      def add_attachments_with_inline_images(obj)
        add_attachments_default(obj)

        # route/path to attachments
        # need to get this from redmine installation
        path = "/attachments/download"

        issue_description = obj.description

        obj.attachments.each do |att|
          if @images.has_value?(att.filename)
            str_r = Regexp.escape("#{@strOpen}#{att.filename}#{@strClose}")
            regex = Regexp.new(str_r)
            issue_description.scan(regex).each do |match|
              tmp_desc = issue_description.gsub(match, "#{@strOpen}#{path}/#{att.id}/#{att.filename}#{@strClose}")
              issue_description = tmp_desc
            end
          end
        end

        obj.description = issue_description
        obj.save!

      end

      
    end # module InstanceMethods
  end # module MailHandlerPatch
end # module RedmineEmailInlineImages

# Add module to MailHandler class
MailHandler.send(:include, RedmineEmailInlineImages::MailHandlerPatch)
