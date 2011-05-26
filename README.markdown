**Queryalize** lets you use Rails 3 to build queries just like with `ActiveRecord::QueryMethods`,
except you can serialize the end result. This is useful for running queries that potentially
return large result sets in the background using something like Resque or Delayed::Job.

Normally, using `ActiveRecord::QueryMethods`, you build queries like this:

    query = User.where(:name => "something").order("created_at DESC")
    
With **Queryalize**, it's only a little different:

    query = Querialize.new(User).where(:name => "something").order("created_at DESC")

However, now you get all of this goodness:

    # NOTE the following methods DO NOT query the database,
    # they return a representation of the query itself in one 
    # of the following formats

    json = query.to_json # => query as json data
    yaml = query.to_yaml # => query as yaml data
    hash = query.to_hash # => query as ruby hash
    
    new_query_from_json = Queryalize.from_json(json)
    new_query_from_yaml = Queryalize.from_yaml(yaml)
    new_query_from_hash = Queryalize.from_hash(hash)

# Why?

Imagine, for example, that you have a database that organizes music into several genres. 
You have built an admin interface that allows the administrator to filter the catalog of 
music by genre, and run updates against the result set. However, the database is large, 
and the query for "electronica" returns 1,000,000+ results. The administrator wants to 
re-process these entries such that the genre is "electronic" (without the annoying 'a' 
at the end). 

Unfortunately, your schema is setup in such a way that you cannot simply run a single 
"UPDATE." Rather, you must iterate through each individual record and update its genre. 
Ouch. There is no way you can allow this to happen during the request, or it will certainly 
timeout. So you decide to queue the update, but how do you tell the queue workers which 
records to update? You could try to capture just the ids from the records, but you'd still 
need to store 1,000,000+ ids somewhere so the queue worker can reference them later, not to 
mention that actually collecting the ids takes a healthy amount of time and memory, and 
will probably also time out. You could build up your query and then use `to_sql` to pass 
the raw SQL to the queue worker, but then you can't use useful methods like 'find_each' in 
the queue task. 

The solution is to serialize the query you've built, and then rebuild it in the queue task. 
It ends up looking something like this (if you're using Delayed::Job):
    
    query = Queryalize.new(Music).joins("JOIN #{Genre.table_name} ON #{Genre.table_name}.music_id = #{Music.table_name}.id").where(["#{Genre.table_name}.name = ?", 'electronica'])
    # see 1. below
    
    worker = GenreWorker.new({
      :update => 'electronic',
      :query  => query.to_json
    })
    
    Delayed::Job.enqueue(worker)
    
    # 1.
    # written this way to demonstrate chaining, but a slightly cleaner way would be:
    # genres = Genre.table_name
    # query  = Queryalize.new(Music)
    # query  = query.joins("JOIN #{genres} ON #{genres}.music_id = #{genres}.id")
    # query  = query.where(["#{genres}.name = ?", 'electronica'])
    
The `GenreWorker` method then looks something like this:

    class GenreWorker
    
        def initialize(args)
          @update = args[:update]
          @query  = args[:query]
        end
        
        def perform
          Queryalize.from_json(@query).find_each do |music|
            music.genre.update_attribute(:name => @update)
          end
        end
      end
    end
    
Notice the query was serialized and reconstructed to its original state, so you
can seamlessly use ActiveRecord features like `find_each`. Simple!