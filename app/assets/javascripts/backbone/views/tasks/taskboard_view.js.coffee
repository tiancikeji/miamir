Miamir.Views.Tasks ||= {}

#必须继承后使用
class Miamir.Views.Tasks.TaskboardView extends Backbone.View
  template: JST["backbone/templates/tasks/taskboard"]
  
  className: "span4"

  initialize: () =>
    @options.tasks.bind 'reset', @addAll
    @options.tasks.bind 'add', @addOne 
    @options.tasks.comparator = (task)->
      return task.get 'id'
    _.bindAll @, "drop"
    _.bindAll @, "remove"
    _.bindAll @, "on_error"
    
  addAll: () =>
    @options.tasks.each(@addOne)

  addOne: (task) =>
    task.bind 'drag_completed',@remove
    view = new Miamir.Views.Tasks.TaskCardView({model : task})
    @$(".well-taskboard").append(view.render().el).fadeIn()

  remove:(event)=>
    @options.tasks.remove event.old_task
    event.old_task.unbind 'drag_completed',@remove

  render: () =>
    $(@el).html(@template(name:@name))
    @addAll()
    @$(".well-taskboard").attr("id",@name)
    @$(".well-taskboard").droppable({
      accept: @options.accepts,
      activeClass: "well-taskboard-active",
      drop: @drop
    })
    return this

  drop: (event,ui)->
    that = this
    cid = $(ui.helper).attr('data-cid')
    _.each @options.from_tasks,(from_collection)->
      from_collection.find (from_task)->
        if from_task.cid == cid
          from_task.bind "put_error",that.on_error
          that.dropped_handle.call that,from_task

  on_error:(xhr,task)->
    bootbox.classes "alert-box"
    switch xhr.status
      when 400 then bootbox.alert "一手提不住两条鱼，一眼看不清两行代码。"
      when 401 then bootbox.alert "这不是你的任务。"
      when 409 
        bootbox.classes "prompt-box"
        estimate_view = new Miamir.Views.Tasks.EstimateView({model:task})
        bootbox.confirm estimate_view.render().el, (result) ->
          estimate_view.save() if result

    task.unbind "put_error",@on_error

  
class Miamir.Views.Tasks.ReadyTaskboardView extends Miamir.Views.Tasks.TaskboardView
  initialize: () =>
    Miamir.Views.Tasks.TaskboardView.prototype.initialize.call(this)
    @name = "Ready"
    _.bindAll @, "on_checkout"

  dropped_handle:(from_task)->
    that = this
    from_task.bind "drag_completed",@on_checkout
    from_task.checkout()

  on_checkout:(event)->
    this.options.tasks.add(event.new_task,{silent: true})
    this.render()
    event.old_task.unbind "drag_completed",@on_checkout

class Miamir.Views.Tasks.ProgressTaskboardView extends Miamir.Views.Tasks.TaskboardView
  initialize: () =>
    Miamir.Views.Tasks.TaskboardView.prototype.initialize.call(this)
    @name = "Progress"
    _.bindAll @, "on_checkin"
  #override add one
  addOne: (task) =>
    task.bind 'drag_completed',@remove
    view = new Miamir.Views.Tasks.ProgressTaskCardView({model : task})
    @$(".well-taskboard").append(view.render().el).fadeIn()

  dropped_handle:(from_task)->
    from_task.bind "drag_completed",@on_checkin
    from_task.checkin()

  on_checkin:(event)->
    @options.tasks.add(event.new_task,{silent: true})
    @render()
    event.old_task.unbind "drag_completed",@on_checkin

class Miamir.Views.Tasks.DoneTaskboardView extends Miamir.Views.Tasks.TaskboardView
  initialize: () =>
    Miamir.Views.Tasks.TaskboardView.prototype.initialize.call(this)
    @name = "Done"

  dropped_handle:(from_task)->
    that = this
    from_task.bind "drag_completed",(event)->
      that.options.tasks.add(event.new_task,{silent: true})
      that.render()
    from_task.done() 