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

      when 'votes'      
        navigate('votes')
        t = Template.globalvotes

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
  Template.nav.rendered = ()->
    console.log "try to i18n"

  #hello
  Template.hello.events(
    'click a': ()->
        Session.set('page', 'inventory')
    )

  #inventory
  Template.inventory.pixlist = ()->
    list = Objects.find({},{sort:{name:1}}).fetch()
    #console.log list
    list

  Template.inventory.events(
    'click a' : (evt)->
      evt.preventDefault()
      link=$(evt.currentTarget)
      Session.set('id',link.attr('id'))
      Session.set('page','picture')
    )

  #picture
  Template.picture.file = ()->
    if(Session.get('id')?)
      pix = Objects.findOne({name: Session.get('id')})
      if(pix?)
        console.log pix
        pix

  Template.votes.voteslist = ()->
    if(Session.get('id')?)
      pix = Objects.findOne({name: Session.get('id')})
      if(pix?)
        _(pix.objects).each (object,keyObject)->
          object.votes = _(object.votes).sortBy (v)->
            -v.priority

          _(object.votes).each (vote, keyVote)->
            pix.objects[keyObject].votes[keyVote].priority = vote.priority * 100/3
            switch vote.priority
              when 1
                l = "*"
              when 2
                l = "**"
              when 3
                l = "***"

            pix.objects[keyObject].votes[keyVote].label = l




            if(Meteor.userId() ==  vote.userid )
              pix.objects[keyObject].votes[keyVote].user = "vous"
              pix.objects[keyObject].userHasVoted = true
            else
              if(vote.userid)
                address = Meteor.users.findOne({_id : vote.userid}).emails[0].address
                console.log address
                pix.objects[keyObject].votes[keyVote].user = address
            
            console.log 'vote : ',vote, keyVote
        console.log pix
        pix.objects

  Template.picture.events(

    #ajout d'un vote à un objet existant
    'click #addVote,#changeVote' : (evt)->
      evt.preventDefault()
      $('#description').val $(evt.currentTarget).attr('rel')
      $('#description').prop('disabled',true)
      $('#frmVotes').fadeIn('fast')
      $('a.addVote').fadeOut('fast')

    #ajout d'un nouvel objet
    'click #addObject' : (evt)->
      evt.preventDefault()

      $('#frmVotes')[0].reset()
      $('#description').prop('disabled',false)


      $('#frmVotes').fadeIn('fast')
      $('a.addVote').fadeOut('fast')

    'click #save' : (evt)->
      evt.preventDefault()
      name = Session.get("id")
      priority = $('#vote').val()
      description = $('#description').val()
      pix = Objects.findOne({name: name})
      descList = _(pix.objects).pluck('description')
      if _(descList).contains(description)
        console.log 'object found : ', description
        o = Objects.findOne({_id : pix._id, "objects.description": description, "objects.votes.userid" : Meteor.userId()})
        if(o)
          Meteor.call "updateVote", pix, description, priority, Meteor.userId(), (err, nb)->
            if(err)
              console.log('err :', err)
            else
              console.log('ok : ', nb, 'updated')
        else
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
      $('#frmVotes').fadeOut('fast')      
      $('a.addVote').fadeIn('fast')

    )

  #votes
  Template.globalvotes.voteslist = ()->
    pixList = Objects.find({objects: {$exists: true}})
    pixList

  Template.globalvotes.events(
    'click a' : (evt)->
      evt.preventDefault()
      link=$(evt.currentTarget)
      Session.set('id',link.attr('href'))
      Session.set('page','picture')
    )

if (Meteor.isServer) 
  Meteor.startup ()->
    # Meteor.AppCache.config({firefox: true});
    console.log "ok"

