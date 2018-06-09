---
layout: post
title:  "q as a WebSocket client"
categories: kdb q websocket gdax cryptocurrency
---

q has been able to act as a WebSocket client since v3.2, but the default usage
is not the most intuitive, requiring the construction of a raw HTTP request
string to be sent to the server e.g.

{% highlight q %}
q).z.ws:{0N!x;} / print incoming msgs to console, no echo.
q)r:(`$":ws://demos.kaazing.com")"GET /echo HTTP/1.1\r\nHost: demos.kaazing.com\r\n\r\n"
q)r
4i
"HTTP/1.1 101 Web Socket Protocol Handshake\r\nConnection: Upgrade\r..
q)neg[r 0]"echo"
q)"echo"
{% endhighlight %}

In this example, an echo server is used which will simply echo whatever is sent
to it. Note that in addition to having to manually construct the query, the
handle returned is a positive int, while WebSockets require async messaging,
and therefore need a negative handle. Additionally, by default all messages
arriving over a WebSocket will be handled by `.z.ws`, which is a little tricky
if you're connecting to multiple servers from one q session.

To combat these annoyances, I built [ws.q][wsq-repo]. This is a very simple
library to wrap around the above functionality & provide WebSocket client
functionality in a more convenient manner.

To set up `ws.q`, clone the repo recursively e.g.

{% highlight bash %}
$ git clone --recursive https://github.com/jonathonmcmurray/ws.q.git
{% endhighlight %}

(The `--recursive` flag is necessary to also pull reQ, an HTTP request library
which is used by `ws.q`)

`ws.q` allows for multiple callback functions, one per connection, set when
opening a WebSocket connection. Opening a connection is via `.ws.open`, which
takes two arguments, the URL (as hsym, symbol or string) & the name of callback
function for this connection (as symbol). `.ws.open` will return the negated
handle, ready for use in messaging. Taking the earlier example of the echo
server:

{% highlight q %}
q)\l ws.q
q).echo.upd:{show x}
q).echo.h:.ws.open["ws://demos.kaazing.com/echo";`.echo.upd]
q).echo.h
-4i
q).echo.h"echo"
q)"echo"
{% endhighlight %}

A table of open connections is found in `.ws.w`:

{% highlight q %}
q).ws.w
h| hostname          callback
-| ---------------------------
4| demos.kaazing.com .echo.upd
{% endhighlight %}

As mentioned before, it is possible to open multiple concurrent WebSocket
connetions:

{% highlight q %}
q).bfx.upd:{.bfx.x,:enlist x}                                   //define upd func for bitfinex
q).spx.upd:{.spx.x,:enlist x}                                   //define upd func for spreadex
q).bfx.h:.ws.open["wss://api.bitfinex.com/ws/2";`.bfx.upd]      //open bitfinex socket
q).spx.h:.ws.open["wss://otcsf.spreadex.com/";`.spx.upd]        //open spreadex socket
q).bfx.h .j.j `event`pair`channel!`subscribe`BTCUSD`ticker      //send subscription message over bfx socket
q).bfx.x                                                        //check raw messages stored
"{\"event\":\"info\",\"version\":2,\"platform\":{\"status\":1}}"
"{\"event\":\"subscribed\",\"channel\":\"ticker\",\"chanId\":3,\"symbol\":\"tBTCUSD\",\"pair\":\"BTCUSD\"}"
"[3,[8903.2,67.80649424,8904.2,49.22740929,27.3,0.0031,8904.2,43651.93267067,9177.5,8752]]"
q).spx.x                                                        //check raw messages stored
"{type:\"poll\"}"
"{type:\"poll\"}"
"{type:\"poll\"}"
"{type:\"poll\"}"
q).ws.w                                                         //check list of opened sockets
h| hostname           callback
-| ---------------------------
3| api.bitfinex.com   .bfx.upd
4| otcsf.spreadex.com .spx.upd
{% endhighlight %}

Also present on the repo is an example WebSocket based feedhandler for the
[GDAX][gdax] cryptocurrency exchange, which provides a [WebSocket API][gxapi].
A number of other cryptocurrency exchanges provide WebSocket feeds, and I plan
to add more example feedhandlers to this repo in time for some of them; keep an
eye out for those if you're interested!

The repo also contains two files called `wsu.q` & `wschaintick.q`; these files
provide functionality for a chained TP which republished data from a regular
tickerplant over WebSockets in JSON format - this will be the subject of a 
future post, but they should already be in a usable state if you need to stream
data from your TP over a WebSocket (e.g. perhaps to an HTML & JS dashboard,
rather than using some form of polling).

[wsq-repo]:      https://github.com/jonathonmcmurray/ws.q
[gdax]:          https://www.gdax.com/
[gxapi]:         https://docs.gdax.com/#websocket-feed