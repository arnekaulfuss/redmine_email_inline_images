module RedmineEmailInlineImages

    module IssuePatch

        def self.included(base) # :nodoc:
            base.extend(ClassMethods)
            base.send(:include, InstanceMethods)

            # Same as typing in the class 
            base.class_eval do
                unloadable # Send unloadable so it will not be unloaded in development
                after_save :update_inline_images
            end

        end

        module ClassMethods
        end

        module InstanceMethods
            # update issue inline images with full path
            # to prevent overlapping names
            def update_inline_images
                abc = true

            end

        end

    end

end