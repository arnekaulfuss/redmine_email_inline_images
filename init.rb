require 'redmine'
require 'mail_handler_patch'
require 'email_inline_images_hooks'

#Rails.configuration.to_prepare do
#  unless MailHandler.included_modules.include? RedmineEmailInlineImages::MailHandlerPatch
#    MailHandler.send(:include, RedmineEmailInlineImages::MailHandlerPatch)
#  end
#end

Redmine::Plugin.register :redmine_email_inline_images do
  name 'Redmine email inline images plugin'
  author 'credativ Ltd'
  description 'Handle inline images on incoming emails, so that they are included inline in the issue description'
  version '4.0.0'
  requires_redmine :version_or_higher => '4.0.0'
end
