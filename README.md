Using Rails to build a News site with XML, JSON, and Mobile support
==========
Modern web applications need to be able to support multiple clients, from
desktop browsers to mobile phones, and even the occasional content management
system needs to be able to play nicely. We can use Ruby on Rails
to quickly build a flexible back-end that can support many front-ends.

To demonstrate, we'll build a simple Campus News site for a ficticious
university. It needs to work with the campus-wide content management
system and needs a public mobile web interface that people
can view on their phones.

We'll start out building a very basic administrative interface
for adding news items, and then we'll explore how to publish
those as JSON, XML, and then integrate jQuery Mobile.


Setting Up Our Environment
------

First, we'll create a completely reproducible
environment for our application, using RVM, the
Ruby Version Manager.

    $ rvm install 1.9.2
    $ rvm gemset create news
    $ rvm gemset use news
    
Our newly created gemset will be empty. Let's
get Rails installed...

    $ gem install rails
    
After Rails finishes installing its core dependencies,
we can create a new application.
    
    $ rails new news
    
This creates a CMS folder and starts installing
several more libraries like CoffeeScript, Sass, and
related libraries by using Bundler. RVM can manage
gems, but Rails likes it better if we use Bundler. Thankfully
they work rather well together.

Next, let's go into our app and create a new rvmrc file:

    $ cd cms
    $ rvm --rvmrc --create 1.9.2@news
    
This way, when we go into this folder again in a new Terminal session,
we'll automatically switch over to the right version
of Ruby and the right Gemset.

We finally have our base app configured. Let's get to work on some code.

Creating a news item
---------------
In our very simple news system, we're going to store pages in the database. Each page will
have body content, some keywords, and a descriptive title we can use to locate
the page. 

Let's create the model and database table:

    $ rails g model news_item name:string body:text
    $ rake db:migrate
    
While we're in here, let's validate that we have to have valid names, valid
content, and a valid slug.

We'll validate that we have to fill in a name and the page's content. A valid slug will
only allow letters, numbers, dashes, and underscores.

As good Rails developers, we should write tests for this first. Our first two tests are
easy - we verify that if we create new pages without names or contents then we'll have
error messages in the collection of errors.

So, in `test/unit/news_item_test.rb` we'll have a couple of basic tests:

    require 'test_helper'

    class NewsItemTest < ActiveSupport::TestCase
  
      def test_requires_name
        n = NewsItem.new
        n.valid?
        assert n.errors[:name].include?("can't be blank")
      end
  
      def test_requires_body
        n = NewsItem.new
        n.valid?
        assert n.errors[:body].include?("can't be blank")
      end
    end

Rails 3.1.1 includes the Turn gem by default, and unfortunately it can interfere
with our tests. Open up `gemfile` and remote this section:

    group :test do
      # Pretty printed test output
      gem 'turn', :require => false
    end

and then run 

    $ bundle
    
again. We can now run our tests with

    $ rake test
    
and they fail since we haven't added the validation. Making them pass is as easy as adding 

    validates_presence_of :name, :body 
    
to our model.

Admin Interface
-----

Scaffolding is bad for the soul, so we'll just avoid it. Let's generate a news item management controller
and some stub pages which we'll turn into forms and lists

    $ rails g controller admin/news_items index new show edit
  
This is going to be an extremely trivial controller. It will follow the typical design pattern of Rails, 
and we'll skip writing functional tests for the new, index, show, and edit actions.

    class Admin::NewsItems < ApplicationController
      def index
        @news_items = NewsItem.all
      end
    end
    
However, when we create and update pages, we'll have to do something
based n the output, so we will write tests for those. First, let's
tackle the views, though.

For `views/admin/news_items/index.html.erb`, just make a simple table
that lists the items.

    <h2>News Items</h2>

    <p><%=link_to "Add News Item", new_admin_news_item_url%>

    <table>
      <tr>
        <th>Name</th>
        <th colspan="3">Actions</th>
      </tr>
      <% @news_items.each do |news_item| %>
      <tr>
        <td><%= link_to "name", admin_news_item_url(news_item) %></td>
        <td><%= link_to "edit", edit_admin_news_item_url(news_item) %></td>
        <td>
          <%= button_to "delete", admin_news_item_url(news_item), 
                          :method => "delete",
                          :confirm => "This will delete the news item. Are you sure?"
          %>
        </td>
      </tr>
      <% end %>
    </table>


Before we can view this, we have to alter our `config/routes.rb` file and remove
the routes the generator placed in, and replace it with

    namespace :admin do
      resources :news_items
    end  

Now we can start our server with

    $ rails server
    
and visit http://localhost:3000/admin/news_items

where we'll see absolutely no items.  Let's build the form for this. Edit 
`app/views/admin/news_items/new.html.erb` and add this:
    
    <h2>New News Item</h2>
    <%= render "form" %>
    <p><%=link_to "Back", admin_news_items_url %></p>
    
This will render a "form partial" which we'll create. A partial lets us share
code. Our new and edit forms will be exactly the same, so let's share 
the code. Create `app/views/admin/news_items/_form.html.erb`.  The underscore
tells Rails it's a partial rather than a real view.

    <%= form_for [:admin, @news_item] do |f| %>
      <div class="row">
        <%= f.label :name %>
        <%= f.text_field :name %>
      </div>
      <div class="row">
        <%= f.label :body %>
        <%= f.text_area :body %>
      </div>

      <%= f.submit %>

    <% end %>
    
The `form_for [:admin, @news_item]` line handles creating the 
proper form action and method based on the object we pass in. But we need to create 
this object instance somewhere. Add this to the controller:

    def new
      @news_item = NewsItem.new
    end
    
Now, refresh the page.

Fill in the fields and press the Create button. You'll see an error called "Unknown Action". This is
because our controller isn't handling the the request.

When we successfully save a news item, we want to redirect users to the list 
page. Let's write a quick test for that. Open
`test/functional/admin/news_items_controller_test.rb` and replace this code:

  require 'test_helper'

  class Admin::NewsItemsControllerTest < ActionController::TestCase
    def test_redirects_to_list_when_saved
      post :create, :news_item => {:name => "Test", :body => "test"}
      assert_redirected_to admin_news_items_url
    end
  end

Run the tests with

    rake test
    
and we'll get a failure. We need to implement this controller
action.

    def create
      @news_item = NewsItem.new(params[:news_item])
      if @news_item.save
        redirect_to admin_news_items_url, :notice => "Created successfully."
      end
    end
    
Running the test again makes everything work well, but
what about when we don't fill things out right? Let's write the 
test for that case:

    def test_redisplays_form_when_save_fails
      post :create
      assert_template :new
    end

Then to make it pass we modify our controller:

    def create
      @news_item = NewsItem.new(params[:news_item])
      if @news_item.save
        redirect_to admin_news_items_url, :notice => "Created successfully."
      else
        render :action => "new"
      end
    end

Back in the browser, if we refresh, we'll see our news item in the list.

Now let's handle displaying the news item. To display the item, we have to
select it from the database so that the view can see it. In the controller,
we add this method:

    def show
      @news_item = NewsItem.find(params[:id])
    end

When we visit /admin/news_items/1,  the id gets passed in
and the controller can pull it out of the parameters object, passing
it to the finder to grab the record.

We simply need to make a view to display this record. 
Modify app/views/admin/news_items/show.html.erb to nicely display
the content.
     
    <h2>Preview</h2>
    <%= render :partial => "/shared/news_item", :locals => {:news_item => @news_item} %>
    <p><%= link_to "Edit", edit_admin_news_item_url(@news_item) %></p>
    <p><%= link_to "Back", admin_news_items_url %></p>
    
We'll put the actual news item template in another partial. This way
we can use it on the public side. We'll create the app/views/shared folder
and place this markup in _news_item.html.erb in that folder:

    <article class="body">
      <header>
        <h1><%= @news_item.name %></h1>
      </header>
      <%= @news_item.body %>
    </article>
    
Next, let's handle editing our existing record. In order to get the form
to load, we have to add a method to the controller for editing.

    def edit
      @news_item = NewsItem.find(params[:id])
    end

Then we can edit our edit view. We get to reuse the same form partial again!

    <h2>Edit News Item</h2>
    <%= render "form" %>
    <p><%=link_to "Back", admin_news_items_url %> </p>

When we click on the form, it loads up. But press Update. It breaks.

Just like with creating items, updating items can have two results. If 
the record saves, we want to go back to the list, and it if doesn't
save then we want to go back to the edit page. We need tests for this.

In test/functional/admin/news_items_controller_test.rb, add this test:

    def test_redirects_to_list_when_updated
      news_item = NewsItem.create :name => "Test", :body => "Test"
      put :update, :id => news_item.id, :news_item => {:name => "Test", :body => "test"}
      assert_redirected_to admin_news_items_url
    end
  
Rails assumes that update requests will use the HTTP PUT verb, and that
is what our forms generate. So we need to make our tests work that way
too. In addition, we need a record to update, so in our test we quickly
create a news item. When we make the `put` request, we pass the id of the post
we want to update followed by the form parameters.
  
We run the tests to ensure it fails, then implement the controller's update
action like this:

    def update
      @news_item = NewsItem.find params[:id]
      if @news_item.update_attributes(params[:news_item])
        redirect_to admin_news_items_url, :notice => "Saved successfully."
      end
    end
    
First we find the record again, since this is a new request and things could have
changed. Then we pass the new form data to the update_attributes method. This
method returns a boolean value which we evaluate to see if the save worked.

Now we add the test for the failing case:

    def test_redisplays_form_when_update_fails
      news_item = NewsItem.create :name => "Test", :body => "Test"  
      put :update, :id => news_item.id, :news_item => {:name => "", :body => ""}
      assert_template :edit
    end
    
This test looks a lot like the last one, but this time we just
don't send blank values for the name and body. These should be
invalid per our business logic we wrote earlier.

Finally, we implement the failing case in the controller  

    def update
      @news_item = NewsItem.find params[:id]
      if @news_item.update_attributes(params[:news_item])
        redirect_to admin_news_items_url, :notice => "Saved successfully."
      else
        render :action => "edit"
      end
    end
    
Back in the browser, refresh. You should new see changes to the
entry.

Showing Status Messages
---------
Our application uses a default template in `app/views/layouts/application.html.erb`. This
file contains the outer HTML that wraps our pages. Let's
modify it so it displays the success message we send from the
controller when we save records. While we're in there, we'll fix up 
the markup a bit, and add a header and a footer.

    <!DOCTYPE html>
    <html>
      <head>
        <title>News</title>
        <%= stylesheet_link_tag    "application" %>
        <%= javascript_include_tag "application" %>
        <%= csrf_meta_tags %>
      </head>
      <body>

      <header>
        <h1>Campus News</h1>
      </header>

      <% if notice %>
        <div id="notice"><% =notice %></div>
      <% end %>

      <section>
        <%= yield %>
      </section>

      <footer>
        <h4>Copyright &copy; Campus</h4>
      </footer>

      </body>
    </html>

When we review the page again, our layout is in place and things are moving
in the right direction.  Our back end is all set up.  We can handle deleting records another time. 
Let's build the public-facing news feed.


Building the News Feeds
--------
We want to list all stories, starting with the newest one first.
First we generate a controller for our public news feed

    $ rails g controller news
    
In the controller's action, we'll fetch the latest 10 news
items. We could limit, but instead, we'll use a pagination
plugin called Kaminari.

Open `Gemfile` and add

    gem 'kaminari'
 
Now stop the web server with CTRL+C and run

    $ bundle
    
to install and fetch the new Kaminari library. When that's done,
we can restart our server.

    $ rails server

 
Next, we open our news_controller.rb and create an index
action that fetches the news items in descending order by
created_at date. When we generated our models and database table,
Rails added created_at and updated_at timestamps to our database
automatically.

    def index
      @news_items = NewsItem.order("created_at desc").page(params[:page])
    end
    
Our app/views/news/index.html.erb file is going to be very simple.

    <%=paginate @news_items %>

    <%= render :partial => "/shared/news_item", :collection => @news_items %>
    
We can pass our entire collection to the shared partial we made and it will 
automatically loop the results. Pretty cool, but we're not quite done.
   
Before we can visit this news list in our browser, we have to
modify the Routing system. We open config/routes.rb and add this to the top:

    resources :news, :only => [:index, :show]

Now we can visit http://localhost:3000/news/ and see our items.

Exposing data
-------

If we alter our index action slightly, we can serve up our page as JSON or XML data. We simply use
a respond block.

    def index
      @news_items = NewsItem.order("created_at desc").page(params[:page])

      respond_to do |format|
        format.html #do nothing.
        format.json { render :json => @news_items.to_json }
        format.xml { render :xml => @news_items.to_xml }
      end

    end

If we do nothing, Rails always looks for a view file with the same name as
the controller's action in a folder with the controller's name. So that's 
the default case. But if we want JSON or XML data, we
can handle that.

When we request a URL, Rails determines the format by looking at 
the request. http://localhost/news is assumed to be HTML. If
we request http://localhost/news.json now, we'll see a JSON
representation of our data. And we can send XML data
with http://localhost/news.xml so a CMS can consume it.


Getting Mobile with Rails
------

We use formats to handle mobile devices in Rails. It's really
as simple as that. If we can serve different views like JSON
or XML based on the format type, we simply define a format
type for mobile devices.

We edit config/initializers/mime_types.rb and add a MIME type
alias, saying that we'll associate .mobile extensions
with the HTML Mime type.

    Mime::Type.register_alias "text/html", :mobile
    
Now, we can start serving mobile views to people.

To test this out, we'll create a new file in 
app/views/controllers/news/index.mobile.erb and put some simple text in it:

    <h1>Hello from Mobile</h1>
    
The view files all have the format defined as part of their name. We could
have a index.txt.erb file if we wanted to, and make the output of that file
a simple text version of our items.
    
When we visit http://localhost:3000/news.mobile, we'll see that output. Unfortunately
we still see our default application layout. We need something more suitable for
mobile sites.

To fix this, we'll create a new application layout that brings in
the jQuery Mobile library. We can create a new application layout, but instead of
application.html.erb, we'll call it application.mobile.erb. This way it gets picked up when we
request the mobile format.

    <html>
      <title>Campus News</title>
      <link rel="stylesheet" 
            href="http://code.jquery.com/mobile/1.0rc2/jquery.mobile-1.0rc2.min.css" />

      <%= javascript_include_tag "application" %>
      <script src="http://code.jquery.com/mobile/1.0rc2/jquery.mobile-1.0rc2.min.js"></script>
      <%= csrf_meta_tag %>

      <body>
        <div data-role="page">
          <%= yield %>
        </div>
      </body>

    </html>

Now let's build our mobile version of the news list. In app/views/news/index.mobile.erb,
we add just a tiny bit of code that links to the detail page for the news item.

    <div data-role="header">
      <h1><%= @news_item.name %></h1>
      <%= link_to 'Home', news_url, "class" => "ui-btn-right" %>
    </div>

    <div data-role="content">
      <%= @news_item.body %>
    </div>
  
When we bring up http://localhost:3000/news.mobile in the browser, we see our 
list of news items. But when we click each item, we get an error because
it can't load the show page.
  
To make this work, we add a show action to our controller to fetch the news item.

    def show
      @news_item = NewsItem.find params[:id]
    end
    
and implement the show view. Since we're only using this on the mobile
version, we'll only need to create the show.mobile.erb version, which will
look like this:

    <div data-role="header">
      <h1><%= @news_item.name %></h1>
      <%= link_to 'Home', news_url, "class" => "ui-btn-right" %>
    </div>
 
    <div data-role="content">
      <%= @news_item.body %>
    </div>
    
When we visit http://localhost:3000/news.mobile now, we see our headlines 
and our detail pages. But this URL is long. Let's shorten it.


Setting the home page
-----
Let's make our news items list the default page when we visit
http://localhost:3000. To do that, we make a default route.

Back in config/routes.rb, we add this line below the admin namespace

    root :to => "news#index"

This tells Rails which controller and action should be our home page. But when
we visit localhost:3000/ we still see the "Welcome Aboard" page.

This is because Rails can actually serve static web pages from the
public folder, and there's one in there now called index.html.  Delete
that file and you'll now see the news page.
Using Subdomains To Set The Format
------------

    def detect_mobile
      request.format = "mobile" if request.subdomains.first == "mobile"
    end

    before_filter :detect_mobile
    
Now, when we request the url http://mobile.localhost.dev:3000/ we'll get our 
mobile version.
    
Wrapping Up
-------

In this tutorial, we explored how we can use Rails as the backend for our information,
leveraging its responders to display our data in multiple formats. From here we can use external
systems to pull in the data, or create an RSS export of the items. We can
also expand out the admin section using responders to build out an API that we can use 
to let external applications put records into our database.


