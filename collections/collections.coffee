#collections

if (Meteor.isServer) 

  Objects = new Meteor.Collection('objects')
  
  Meteor.startup ()->
    console.log "collection"
    #fs.readdir '../../../../../public', (err, files)->
    files = fs.readdirSync '../../../../../public/uploads'
      
    console.log files
    cleanedUpFiles = _(files).reject (fileName) ->
      fileName.indexOf('.JPG') < 0;

    _(cleanedUpFiles).each (f)->
      console.log 'updating ',f
      fObject = {name: f, url:'/uploads/'+f}
      o = Objects.upsert({name: f}, $set:fObject)
      # if !o
      #   Objects.insert(fObject)
      #   console.log f+' new file'


    list = Objects.find().fetch()
    console.log list

  Meteor.publish 'objects', ()->
    Objects.find()
    