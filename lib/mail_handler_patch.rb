module RedmineEmailInlineImages

  module MailHandlerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        alias_method :email_parts_to_text_default, :email_parts_to_text
        alias_method :email_parts_to_text, :email_parts_to_text_with_inline_images
      end
    end
    
    module InstanceMethods
      private
      # Overrides the email_parts_to_text method to
      # include inline images from an email for
      # an issue created by an email request

      def email_parts_to_text_with_inline_images(parts)
        email_images = {}
        email.all_parts.each do |part|
            if part['Content-ID']
                if part['Content-ID'].respond_to?(:element)
                    content_id = part['Content-ID'].element.message_ids[0]
                else
                    content_id = part['Content-ID'].value.gsub(%r{(^<|>$)}, '')
                end
                image = part.header['Content-Type'].parameters['name']
                email_images["cid:#{content_id}"] = image
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
          body.scan(/(\[(cid:.*?)\])/).each do |match|
            case Setting.text_formatting
            when 'markdown'
                image_bang = "\n![](#{email_images[match[1]]})"
            when 'textile'
                image_bang = "\n!#{email_images[match[1]]}!"
            else
                image_bang = nil
            end
            tmp_body = body.gsub(match[0], image_bang) if image_bang
            body = tmp_body
          end

          # convert html parts to text
          part.mime_type == 'text/html' ? self.class.html_body_to_text(body) : self.class.plain_text_body_to_text(body)
        end.join("\r\n")

      end

      
    end # module InstanceMethods
  end # module MailHandlerPatch
end # module RedmineEmailInlineImages

# Add module to MailHandler class
MailHandler.send(:include, RedmineEmailInlineImages::MailHandlerPatch)
