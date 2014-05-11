if (Meteor.isClient)
  Objects = new Meteor.Collection("objects")
  Meteor.subscribe('objects')

  #main
  Template.main.content = ()->
    page = Session.get('page')
    switch page
      when 'hello' then t =  Template.hello
      when 'picture'         
        t = Template.picture
        t.file = ()->
         Objects.findOne(Session.get('id'))
      when 'inventory'        
        t = Template.inventory
        t.pixlist = ()->
          list = Objects.find().fetch()
          #console.log list
          list
      else t = Template.hello
    t

  #nav
  Template.nav.events(
    'click a': (evt)->
      evt.preventDefault()
      link = $(evt.currentTarget)
      # console.log link
      page = link.attr("href")
      Session.set('page', page)
    )

  #hello
  Template.hello.events(
    'click a': ()->
        Session.set('page', 'picture')
        console.log "page = picture"
    )

  #inventory
  Template.inventory.events(
    'click a' : (evt)->
      evt.preventDefault()
      link=$(evt.currentTarget)
      Session.set('id',link.attr('id'))
      Session.set('page','picture')
    )

  Template.picture.events(
    'click #save' : ()->
      id = Session.get("id")
      priority = $('#vote').val()
      description = $('#description').val()
      Objects.update(id, $addToSet:{'vote':{'description': description, 'priority': priority}})
    )

if (Meteor.isServer) 
  Meteor.startup ()->
    console.log "ok"

