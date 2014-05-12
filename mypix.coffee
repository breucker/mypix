if (Meteor.isClient)
  Objects = new Meteor.Collection("objects")
  
  Meteor.startup ()->
    Session.set('page', 'hello')
    Session.set('id',null)

  navigate = (href)->
    $(".nav li").removeClass('active')
    $("a[href='"+href+"']").parent().addClass('active')

  #main
  Template.main.content = ()->
    Meteor.subscribe('objects')
    page = Session.get('page')

    switch page
      when 'hello'
       t =  Template.hello
       navigate('hello')  

      when 'picture'  
        if(Session.get('id') is null)
          Session.set('page','hello')
          return

        navigate('picture')
        t = Template.picture

      when 'inventory'      
        navigate('inventory')
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
        Session.set('page', 'inventory')
    )

  #inventory
  Template.inventory.events(
    'click a' : (evt)->
      evt.preventDefault()
      link=$(evt.currentTarget)
      Session.set('id',link.attr('id'))
      Session.set('page','picture')
    )

  #picture
  Template.file = ()->
    if(Session.get('id')?)
      pix = Objects.findOne({name: Session.get('id')})
      if(pix?)
        t.file = ()->
        console.log pix
        pix

  Template.votes.voteslist = ()->
    if(Session.get('id')?)
      pix = Objects.findOne({name: Session.get('id')})
      if(pix?)
        pix.objects

  Template.picture.events(
    'click #save' : (evt)->
      evt.preventDefault()
      name = Session.get("id")
      priority = $('#vote').val()
      description = $('#description').val()
      pix = Objects.findOne({name: name})
      descList = _(pix.objects).pluck('description')
      if _(descList).contains(description)
        console.log 'object found : ', description
        Meteor.call "addVote", pix, description, priority, (err, nb)->
          if(err)
            console.log('err :', err)
          else
            console.log('ok : ', nb, 'updated')
        
      else
        console.log 'creating object : ', description
        Objects.update( 
          pix._id, 
          $addToSet: 
            objects:
              description: description
              votes: [  
                priority: priority
                userid: Meteor.userId()         
              ]
        , (err, nb)->
          if(err)
            console.log('err :', err)
          else
            console.log('ok : ', nb, 'updated')
        )
    )

if (Meteor.isServer) 
  Meteor.startup ()->
    # Meteor.AppCache.config({firefox: true});
    console.log "ok"

