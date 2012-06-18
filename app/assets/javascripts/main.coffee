$ ->
	class window.Todo extends Backbone.Model
		defualts: ->
			done: false,
			index: Todos.nextOrder()
			title: "empty todo..."
		initialize: =>
			@set({"title": @defaults.title}) if not @get("title") 
		toggle: =>
			@save({done: !this.get("done")})
		clear: =>
			@destroy()

	class window.TodoList extends Backbone.Collection
		model: Todo
		url: '/todos'
		done: =>
			@filter (todo) -> todo.get('done')
		remaining: => 
			@without.apply(@, @done())
		nextOrder: =>
			if not @length then 1 else @last().get('index') + 1
		comparator: (todo) ->
			todo.get('index')

	class window.TodoView extends Backbone.View
		tagName: "li"
		template: _.template($('#item-template').html())	#js template
		events:
			"click .toggle": "toggleDone"
			"dblclick label.todo-text": "edit"
			"click button.destroy": "clear"
			"keypress .edit": "updateOnEnter"
		initialize: =>
			@model.bind('change', @render, @)
			# @model.bind('destroy', @remove, @)
			@model.bind('remove', @remove, @)
		render: =>
			$(@el).html(@template(@model.toJSON()))
			@setText()
			@
		setText: =>
			text = @model.get('title')
			@$('.todo-text').text(text)
			@input = @$('.todo-input')
			@input.bind('blur', _.bind(@close, @)).val(text)
		toggleDone: =>
			@model.toggle()
		edit: =>
			$(@el).addClass("editing");
			@input.focus();
		close: =>
			text = @$('.edit').val()
			jsRoutes.controllers.Application.rename(@model.id).ajax
				context: this
				data:
					title: text
				success: ->
					$(@el).removeClass("editing")
					@$('.todo-text').text(text)
				error: (err) ->
					alert "Something went wrong:" + err		
			false
		updateOnEnter: (e) ->
			@close() if e.keyCode is 13
		remove: =>
			$(@el).remove()
		clear: =>
			#@model.destroy()
			#you can use model.destroy() to do delete request, but here we use play jsRoutes
			jsRoutes.controllers.Application.delete(@model.id).ajax
				context: this
				success: ->
					Todos.remove(@model)
				error: (err) ->
					alert "Something went wrong:" + err		
			false

	# Top level view
	class window.AppView extends Backbone.View
		el: $("#todoapp")
		statsTemplate: _.template($('#stats-template').html())  #underscore template
		events: 
			"keypress #new-todo": "createOnEnter"
			"keyup #new-todo": "showTooltip"
			"click #clear-completed": "clearCompleted"
			"click #filters li a": "filter"
			# "click #toggle-all": "toggleAllComplete"
		initialize: =>
			@input = @$("#new-todo")
			Todos.bind('add', @addOne, @)
			Todos.bind('reset', @addAll, @)
			Todos.bind('all', @render, @)
			Todos.fetch()
		render: =>
			@$('#todo-stats').html @statsTemplate
				total: Todos.length
				done: Todos.done().length
				remaining: Todos.remaining().length
		addOne: (todo) ->
			view = new TodoView({model: todo})
			$('#todo-list').append(view.render().el)
		addAll: =>
			Todos.each(@addOne)
		filter: (e) =>
			if $(e.currentTarget).attr('href') is '#/'
				$('#todo-list .item').each -> $(this).show()
			if $(e.currentTarget).attr('href') is '#/active'
				$('#todo-list .item').each -> 
					if $(this).attr('aria-checked') is 'true' then $(this).show() else $(this).hide()
			if $(e.currentTarget).attr('href') is '#/completed'
				$('#todo-list .item').each -> 
					if $(this).attr('aria-checked') is 'false' then $(this).show() else $(this).hide()
		createOnEnter: (e) =>
			text = @input.val()
			return if not text or e.keyCode isnt 13
			# we use play jsroute feature here. however, you can easily use Todos.create to achieve same functionalily
			jsRoutes.controllers.Application.add().ajax
				type: "POST"
				context: this
				data:
					title: text
					index: Todos.nextOrder
					done: false
				success: (tpl) ->
					newTodo = new Todo(tpl)
					Todos.add(newTodo)
				error: (err) ->
					alert "Something went wrong:" + err		
			@input.val('')
			false
		clearCompleted: ->
			_.each(Todos.done(), (todo) -> todo.destroy())
			false
		showTooltip: (e) =>
			tooltip = @$(".ui-tooltip-top")
			val = @input.val()
			return if val is '' or val is @input.attr('placeholder')
			return if @$(".ui-tooltip-top").css('display') is not 'none' 
			show = -> tooltip.fadeIn()
			@tooltipTimeout = _.delay(show, 1000)
			unshow = -> tooltip.fadeOut()
			@tooltipTimeout = _.delay(unshow, 3500)
			
	window.Todos = new TodoList
	window.App = new AppView