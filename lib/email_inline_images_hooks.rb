class RedmineEmailInlineImagesHooks < Redmine::Hook::Listener

    #trying to fix an issue with screenshots (always image00x.png)
    #overlapping textile/markdown links with same filename
    #does not work because not fired on new
    def controller_issues_new_after_save(context={})

        tmp_issue = context[:issue]

        tmp_stop = true

    end

end