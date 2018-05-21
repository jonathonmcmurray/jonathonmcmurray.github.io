---
layout: post
title:  "Creating a REST API powered by kdb+/q"
date:   2018-05-18 15:23:49 +0100
categories: kdb q rest api
---

A few weeks ago I published a post on the AquaQ Analytics (my employer) blog regarding using REST APIs in kdb+. You can read that blog post [on the AquaQ blog][aquaq-blog]. Just for fun, I decided to try building the "other side" - creating a REST API powered by kdb+. The result is found in my GitHub repo, [qwebapi][qwebapi-gh].

![Creating a REST API powered by kdb+/q]({{ "/assets/rest.png" | absolute_url }}){: margin: 0 auto; display: block; }

You may be wondering why you would want to provide a REST API from kdb+ - it provides a very simple method of interoperability with other languages and technologies, beyond those with an existing interface (e.g. with [Fusion][kx-fusion] interfaces from kx). Creating products such as web based dashboards is simplified by having data available over REST APIs, for example.

So far, the simple `api.q` script found in the repo supports defining functions for both GET & POST HTTP methods, as well as defining default parameters and required parameters. In addition, basic HTTP authorization is supported, allowing restriction of access to authorized users.

Some of the ground work for building an HTTP API was already done in [reQ][req-gh], an HTTP requests library, featured in the previously mentioned AquaQ blog point, and nearing a first "release", at which point I'll do a more detailed write-up here. Building on this, it was a fairly quick & simple process to create a very basic HTTP API written in q. This is by no means a "production ready" library, and lacks a number of important features (e.g. error handling, logging etc.)

Using `api.q` is fairly simple; first of all, clone the repo (using the `--recurse-submodules` option to clone reQ as well):

{% highlight bash %}
jonny@kodiak ~ $ git clone --recurse-submodules https://github.com/jonathonmcmurray/qwebapi.git
jonny@kodiak ~ $ cd qwebapi/
jonny@kodiak ~/qwebapi (master) $ tree -L 2
.
├── api.q
├── example.q
├── LICENSE
├── README.md
└── reQ
    ├── examples
    ├── json.k
    ├── LICENSE
    ├── README.md
    ├── req.q
    └── tests

3 directories, 8 files
{% endhighlight %}

Now, within a q session, load the `api.q` script & set a port. In addition, define your API functions; these should be regular KDB functions, registered as an API function using the `.api.define` function. This function takes the name of the function, a dictionary of default values (which will be used for types), a list of required parameters and the supported HTTP methods (`` `GET``,`` `POST`` or `` ` `` for both).

Using [sp.q][sp-q] from kx to provide some example data, here is a simple example of creating a basic API:

{% highlight q %}
q)\l sp.q
q)\l api.q
q)\p 1235
q)example:{select distinct p,s.city from sp}
q).api.define[`example;()!();();`GET]
q)setcity:{[city] cty::city;"City set to: ",string cty}
q).api.define[`setcity;(1#`city)!1#`;`city;`POST]
q)gets:{0!select from s where city=cty}
q).api.define[`gets;()!();();`]
q)getp:{[city;color]ct:city;cl:color;0!select from p where city=ct,color=cl}
q).api.define[`getp;`city`color!`london`red;`color;`]
{% endhighlight %}

We now have a simple HTTP API running on port 1235; we can query this with any tool capable of sending HTTP queries. In other words, the vast majority of programming languages, a number of command line tools (cURL, wget etc.) and so on. For the sake of some examples, we'll use [Postman][postman] to issue some queries to our API.

First off, we'll call the `example` function defined above, with the `GET` method:

![Example function call]({{ "/assets/example.png" | absolute_url }})

Next up, we'll set a city using `setcity`:

![Invalid method]({{ "/assets/invalid_method.png" | absolute_url }})

Oops, wrong method - when we called `.api.define` for this function, we only allowed POST requests:

![setcity function call]({{ "/assets/setcity.png" | absolute_url }})

That's better! Now we can call `gets` to make use of the city we just set:

![gets]({{ "/assets/gets.png" | absolute_url }})

One function left, `getp`:

![Missing parameter]({{ "/assets/missing_param.png" | absolute_url }})

When we defined this one, we made `color` a required parameter, better include it with our request:

![getp]({{ "/assets/getp.png" | absolute_url }})

I haven't shown the use of HTTP basic authorization, but it's quite simple - start the process with `-auth user.txt` where user.txt is a text file containing `user:pass` combinations, one per line. Then, basic authorization will be enabled.

As mentioned above, this is not really a "production ready" library, it is quite rudimentary and rough around the edges. The main point was to see if it was possible to write a REST API in pure q (which it is!). If you actually need to provide a kdb+ backed REST API, I suggest you keep an eye on [AquaQ's GitHub][aq-gh] and [blog][aq-blog] for an upcoming open source release; I'm not a part of the team that's been working on this, so I don't know the full extent of the functionality etc., but I'm quite certain it'll be a lot more polished and robust than this simple script!

[aquaq-blog]:   https://www.aquaq.co.uk/q/using-kdb-with-rest-apis/
[req-gh]:       https://github.com/jonathonmcmurray/reQ
[qwebapi-gh]:   https://github.com/jonathonmcmurray/qwebapi
[aq-gh]:        https://github.com/AquaQAnalytics
[aq-blog]:      https://www.aquaq.co.uk/blog/
[kx-fusion]:    https://code.kx.com/q/interfaces/fusion/
