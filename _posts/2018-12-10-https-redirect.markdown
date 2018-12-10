---
layout: post
title:  "Redirecting HTTP to HTTPS in q"
categories: kdb q http https ssl tls
---

In my [previous post](https://jmcmurray.co.uk/kdb/q/https/api/2018/12/08/https-api-letencrypt.html)
I discussed using Let's Encrypt to generate a CA-signed certificate for use in
q to run an HTTPS server. At the tail end of that post, I mentioned redirecting
HTTP requests to run over HTTPS. Since then, I have written & published a small
package to do exactly that.

This package (available at the [GitHub repo](INSERT LINK)) overwrites `.z.ph` &
`.z.pp` to check if the current request is HTTP (checking `.z.e` to determine
this), & if so, returns a `301 Permanently Moved` HTTP response, redirecting
the client to HTTPS. If the connection is already HTTPS, the exisitng `.z.ph`
or `.z.pp` definition is called as usual.

The package can easily be installed using conda e.g.

```bash
$ conda install -c jmcmurray https-redirect
```

I think this is a fairly straightforward & easy-to-use module, which "should"
require no interaction other than loading:

```q
jonny@grizzly ~/git/qwebapi (master) $ q -E 1 -p 8100
KDB+ 3.6 2018.05.17 Copyright (C) 1993-2018 Kx Systems
l32/ 2()core 1944MB jonny grizzly 127.0.1.1 NONEXPIRE

q).utl.require"webapi"
q)\l example.q
q).utl.require"https-redir"
```

*NOTE: We need to use `-E 1` to allow HTTP connections, which can then be
redirected to HTTPS. With `-E 2`, HTTP connections will signal in a way we
can't catch & respond to*

Also note that we load `webapi` module *first*; `https-redir` requires any
other definitions of `.z.ph` & `.z.pp` to be set before loading.

Following this, any HTTP request will automatically be redirected to HTTPS.

For example, using [reQ](https://jmcmurray.co.uk/kdb/q/http/req/2018/06/19/req-0.1.1-release.html)
in verbose mode, we can see the flow of requests & responses. Note that due to
how q sends server SSL certificates (see note in [previous post](https://jmcmurray.co.uk/kdb/q/https/api/2018/12/08/https-api-letencrypt.html))
we have to disable SSL server verfication for q - other clients such as web
browsers will download intermediate certificates & this will not be an issue.

```q
jonny@grizzly ~ $ export SSL_VERIFY_SERVER=NO
jonny@grizzly ~ $ q
KDB+ 3.6 2018.05.17 Copyright (C) 1993-2018 Kx Systems
l32/ 2()core 1944MB jonny grizzly 127.0.1.1 NONEXPIRE

q).utl.require"req"
q).req.VERBOSE:1b
q).req.g"http://jmcmurray.hopto.org:8100/gettime"
-- REQUEST --
:http://jmcmurray.hopto.org:8100
GET /gettime HTTP/1.1
Host: jmcmurray.hopto.org:8100
Connection: Close
User-Agent: kdb+/3.6
Accept: */*


-- RESPONSE --
HTTP/1.1 301 Moved Permanently
Content-Type: text/html
Content-Length: 227
Connection: close
Location: https://jmcmurray.hopto.org:8100/gettime

<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN"><head><title>301 Moved Permanently</title></head><body><h1>Moved Permanently</h1><p>The document has moved <a href="https://jmcmurray.hopto.org:8100/gettime">here</a></p></body>
-- REQUEST --
:https://jmcmurray.hopto.org:8100
GET /gettime HTTP/1.1
Host: jmcmurray.hopto.org:8100
Connection: Close
User-Agent: kdb+/3.6
Accept: */*


-- RESPONSE --
HTTP/1.1 200 OK
Content-Type: application/json
Connection: close
Content-Length: 40

{"time":"2018-12-10T13:07:41.900367000"}
time| "2018-12-10T13:07:41.900367000"
```

We see here that the first request recieves a `301` status & the redirect is
followed automatically by reQ to send the request to the HTTPS URL.
