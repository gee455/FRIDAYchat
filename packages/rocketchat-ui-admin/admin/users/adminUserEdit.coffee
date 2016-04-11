Template.adminUserEdit.helpers
	canEditOrAdd: ->
		return (Template.instance().user and RocketChat.authz.hasAtLeastOnePermission('edit-other-user-info')) or (not Template.instance().user and RocketChat.authz.hasAtLeastOnePermission('create-user'))

	user: ->
		return Template.instance().user

Template.adminUserEdit.events
	'click .cancel': (e, t) ->
		e.stopPropagation()
		e.preventDefault()
		t.cancel()

	'click .save': (e, t) ->
		e.stopPropagation()
		e.preventDefault()
		t.save()

Template.adminUserEdit.onCreated ->
	@user = this.data

	@cancel = =>
		if @user
			RocketChat.TabBar.setTemplate 'adminUserInfo'
			RocketChat.TabBar.setData @user
			RocketChat.TabBar.showGroup 'adminusers-selected'
		else
			RocketChat.TabBar.closeFlex()
			RocketChat.TabBar.showGroup 'adminusers'

	@getUserData = =>
		userData = { _id: @user?._id }
		userData.name = s.trim(this.$("#name").val())
		userData.username = s.trim(this.$("#username").val())
		userData.email = s.trim(this.$("#email").val())
		userData.password = s.trim(this.$("#password").val())
		userData.requirePasswordChange = this.$("#changePassword:checked").length > 0
		return userData

	@validate = =>
		userData = this.getUserData()

		errors = []
		unless userData.name
			errors.push 'Name'
		unless userData.username
			errors.push 'Username'
		unless userData.email
			errors.push 'E-mail'

		for error in errors
			toastr.error(TAPi18n.__('The_field_is_required', TAPi18n.__(error)))

		return errors.length is 0

	@save = =>
		if this.validate()
			userData = this.getUserData()
			Meteor.call 'insertOrUpdateUser', userData, (error, result) =>
				if result
					if userData._id
						toastr.success t('User_updated_successfully')
					else
						toastr.success t('User_added_successfully')
						@user = Meteor.users.findOne result

					Meteor.subscribe 'fullUserData', userData.username, 1, =>
						Session.set 'showUserInfo', @user._id
						this.cancel()

				if error
					toastr.error error.reason
