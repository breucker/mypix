if (Meteor.isClient)
  Objects = new Meteor.Collection("objects")
  
  Meteor.subscribe('objects')

  Meteor.startup ()->
    Session.set('page', 'hello')
    Session.set('id',null)
  
  #### Routes ###
  Router.configure(
    layoutTemplate: 'main'  
  )

  Router.map ()->
    @.route 'home', 
      path:"/",
      template: 'hello'

    @.route 'inventory', 
      path:"/inventory",
      template: 'inventory'

    @.route 'picture',
      path:"/picture/:pix_id",
      template: 'picture'

    @.route 'votes',
      path:"/votes",
      template: 'globalvotes'

  #nav
  Template.nav.helpers activeIfTemplateIs: (template) ->
    currentRoute = Router.current()
    (if currentRoute and template is currentRoute.lookupTemplate() then "active" else "")

  #hello
  Template.hello.events(
    'click a': ()->
        Router.go('inventory')
    )

  #inventory
  Template.inventory.pixlist = ()->
    list = Objects.find({},{sort:{name:1}}).fetch()
    #console.log list
    list

  #picture
  Template.picture.file = ()->
    if(Router.current().params['pix_id']?)
      pix = Objects.findOne({name: Router.current().params['pix_id']})
      if(pix?)
        #console.log pix
        pix

  Template.votes.voteslist = ()->
    if(Router.current().params['pix_id']?)
      pix = Objects.findOne({name: Router.current().params['pix_id']})
      if(pix?)
        _(pix.objects).each (object,keyObject)->
          object.votes = _(object.votes).sortBy (v)->
            -v.priority

          _(object.votes).each (vote, keyVote)->
            pix.objects[keyObject].votes[keyVote].priority = vote.priority * 100/3
            
            if(Meteor.userId() ==  vote.userid )
              pix.objects[keyObject].votes[keyVote].user = "vous"
              pix.objects[keyObject].userHasVoted = true
            else
              if(vote.userid)
                address = Meteor.users.findOne({_id : vote.userid}).emails[0].address
                #console.log address
                pix.objects[keyObject].votes[keyVote].user = address            
            #console.log 'vote : ',vote, keyVote
        #console.log pix
        pix.objects

  Template.picture.events(
    #ajout d'un vote à un objet existant
    'click #addVote,#changeVote' : (evt)->
      evt.preventDefault()
      $('#description').val $(evt.currentTarget).attr('rel')
      $('#description').prop('disabled',true)
      $('#frmVotes').fadeIn('fast')
      $('a.addVote').fadeOut('fast')

    #suppression d'un vote à un objet existant
    'click #removeVote' : (evt)->
      evt.preventDefault()
      description = $(evt.currentTarget).attr('rel')
      pix = Objects.findOne({name: Router.current().params['pix_id']})
      Meteor.call "removeVote", pix, description, Meteor.userId(), (err, nb)->
        if(err)
          console.log('err :', err)
        else
          console.log('ok : ', nb, 'removed')

    #ajout d'un nouvel objet
    'click #addObject' : (evt)->
      evt.preventDefault()
      $('#frmVotes')[0].reset()
      $('#description').prop('disabled',false)
      $('#frmVotes').fadeIn('fast')
      $('a.addVote').fadeOut('fast')

    'click #save' : (evt)->
      evt.preventDefault()
      name = Router.current().params['pix_id']
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
    pixList = Objects.find({objects: {$exists: true}}).fetch()
    console.log "pixList", pixList
    #picturesList = {}
    _(pixList).each (pix, keyPix)->
      _(pix.objects).each (object,keyObject)->
        object.votes = _(object.votes).sortBy (v)->
          -v.priority

        _(object.votes).each (vote, keyVote)->
          if(Meteor.userId() ==  vote.userid )
            pix.objects[keyObject].votes[keyVote].user = "vous"
            pix.objects[keyObject].userHasVoted = true
          else
            if(vote.userid)
              address = Meteor.users.findOne({_id : vote.userid}).emails[0].address
              console.log address
              pix.objects[keyObject].votes[keyVote].user = address
          
          console.log 'vote : ',vote, keyVote
      #console.log pix

    pixList
  
  Template.globalvotes.helpers(
    label: (p)->
      switch parseInt(p)
              when 1
                return "un peu"
              when 2
                return "beaucoup"
              when 3
                return "passionnément"

    )

if (Meteor.isServer) 
  Meteor.startup ()->
    # Meteor.AppCache.config({firefox: true});
    console.log "ok"

