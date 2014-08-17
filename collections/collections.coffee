#collections

if (Meteor.isServer) 

  Objects = new Meteor.Collection('objects')
  
  Meteor.startup ()->
    console.log "collection building..."
    fs.readdir '../../../../../public', (err, files)->
    files = fs.readdirSync '../../../../../public/uploads'
      
    # console.log files
    cleanedUpFiles = _(files).reject (fileName) ->
      fileName.indexOf('.JPG') < 0;

    _(cleanedUpFiles).each (f)->
      # console.log 'updating ',f
      fObject = {name: f, url:'/uploads/'+f}
      o = Objects.upsert({name: f}, $set:fObject)

    list = Objects.find().fetch()
    console.log _(list).size()," objects in collection"

  Meteor.publish 'objects', ()->
    [
      Objects.find(),
      Meteor.users.find() # this is ugly !! but don't know how to do otherwise...
    ]
  
  Meteor.methods(
    addVote: (pix, description, priority)->
      console.log 'addVote called with ',pix, description, priority
      Objects.update(
        {_id: pix._id, "objects.description":description},
        $push:
          "objects.$.votes":   
            priority: priority
            userid: this.userId         
        , (err, nb)->
          if(err)
            console.log('err :', err)
          else
            console.log('ok : ', nb, 'vote added')
      )
    removeVote: (pix, description, userId)->
      console.log "removing vote : ", "pix ", pix, "description ", description, "userid ", userId
      Objects.update(
        {_id: pix._id, "objects.description":description},
        $pull:
          "objects.$.votes":  
            userid: userId         
        , (err, nb)->
          if(err)
            console.log('err :', err)
          else
            console.log('ok : ', nb, 'vote removed')
      )      

    updateVote: (pix, description, priority, userId)->
      console.log "try to update : ", "pix-->", pix, "description : ", description,"priority :", priority,"user :", userId
      o = Objects.findOne(pix._id, "objects.description":description)
      console.log o.objects
      theObjectKey = null
      theVoteKey = null
      _(o.objects).each (object, objectKey)->
        console.log objectKey, "->",object.votes, "description ", description
        if(object.description == description)
          console.log 'description found'
          theObjectKey = objectKey
          _(object.votes).each (vote, voteKey)->
            if(vote.userid == userId)
              theVoteKey = voteKey
      #if the vote for this object from this user does not exist, we create one and return
      if(theVoteKey is null)
        Objects.update(
          {_id: pix._id, "objects.description":description},
          $push:
            "objects.$.votes":   
              priority: priority
              userid: userId         
          , (err, nb)->
            if(err)
              console.log('err :', err)
            else
              console.log('ok : ', nb, 'vote added')
        )
        return
      #else we update the existing vote
      console.log "objectKey : ", theObjectKey,"voteKey : ", theVoteKey
      vote = {}
      vote["objects."+theObjectKey+".votes."+theVoteKey] =  {priority : priority, userid : userId}
      
      Objects.update(
        {_id: pix._id},
        $set:
           vote
            
        , (err, nb)->
          if(err)
            console.log('err :', err)
          else
            console.log('ok : ', nb, 'vote updated for ',description)
      )

    getUserMail: (userId)->
      u = Meteor.users.findOne({_id : userId})
      console.log u.emails[0].address
      return u.emails[0].address

    exportCsv: ()->
      exportObjects = new Array(new Array("Image","Objet","User","Note"))

      pixList = Objects.find({objects: {$exists: true}}).fetch()
      console.log "exporting ", pixList
      #picturesList = {}
      _(pixList).each (pix, keyPix)->
        _(pix.objects).each (object,keyObject)->
          _(object.votes).each (vote, keyVote)->
            if(vote.userid)
              address = Meteor.users.findOne({_id : vote.userid}).emails[0].address
            exportObjects.push(new Array(pix.name,object.description, address, vote.priority))

      console.log exportObjects
      
      CSV().from(exportObjects).to('../../../../../.out.csv')
      return exportObjects

              
  )

