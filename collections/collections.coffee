#collections

if (Meteor.isServer) 

  Objects = new Meteor.Collection('objects')
  
  Meteor.startup ()->
    console.log "collection building..."
    #fs.readdir '../../../../../public', (err, files)->
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
    Objects.find()
  
  Meteor.methods(
    addVote: (pix, description, priority)->
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
            console.log('ok : ', nb, 'updated')
          )
    )