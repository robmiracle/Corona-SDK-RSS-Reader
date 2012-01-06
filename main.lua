local rss = require("rss")
local print_r = require("utility").print_r

local feedURL = "http://blog.anscamobile.com/feed/"
local feedName = "index.rss"
local baseDir = system.CachesDirectory

function displayFeed(feedName, feedURL)

print("entering displayFeed", feedName, feedURL)

    local function processRSSFeed(file, path)
        print("Parsing the feed")
        local story = {}
        local feed = rss.feed(file, path)
        print_r(feed)
        local stories = feed.items
        native.setActivityIndicator( false )
        print("Num stories: " .. #stories)
        print("Got ", #stories, " stories")
        --print_r(stories)
    end
    
    local function onAlertComplete( event )
        return true
    end
    
    local networkListener = function( event )
        utility.print_r(event)
        if ( event.isError ) then
            local alert = native.showAlert( "RSS", "Feed temporarily unavaialble.", 
                                        { "OK" }, onAlertComplete )
        else
            print("calling processRSSFeed because the feed is avaialble")
            processRSSFeed(feedName, baseDir)
        end
        return true
    end
    
    function MyNetworkReachabilityListener(event)
        --native.showAlert("network", "is reachable", {"OK"})
        print( "isReachable", event.isReachable )
        network.setStatusListener( "blog.anscamobile.com", nil )
        if event.isReachable then
            -- download the latest file
            native.setActivityIndicator( true )
            --native.showAlert("network", "downloading", {"OK"})
            network.download(feedURL, "GET", networkListener, feedName, baseDir)
        else
            print("not reachable")
            --native.showAlert("network", "using cached copy", {"OK"})
            -- look for an existing copy
            local path = system.pathForFile(feedName, baseDir)
            local fh, errStr = io.open( path, "r" )
            if fh then
                io.close(fh)
                print("calling processRSSfeed because the network isn't reachable")
                processRSSFeed(feedName, baseDir)
            else
                local alert = native.showAlert( "RSS", "Feed temporarily unavaialble.", 
                                            { "OK" }, onAlertComplete )
            end
        end
        return true
    end
   
    if network.canDetectNetworkStatusChanges then
        network.setStatusListener( "blog.anscamobile.com", MyNetworkReachabilityListener )
    else
        native.showAlert("network", "not supported", {"OK"})
        print("network reachability not supported on this platform")
    end
end

displayFeed(feedName, feedURL)
