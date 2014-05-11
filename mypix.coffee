if (Meteor.isClient)
 
  

  Template.main.content = ()->
    page = Session.get('page')
    switch page
      when 'hello' then t =  Template.hello
      when 'picture'         
        t = Template.picture
        t.url = '/P9011111.JPG'
        t.name= 'P9011111.JPG'
      else t = Template.hello
    t


  Template.hello.events(
    'click a': ()->
        Session.set('page', 'picture')
        console.log "page = picture"
    )
    
      

if (Meteor.isServer) 
  Meteor.startup ()->
    console.log "ok"

