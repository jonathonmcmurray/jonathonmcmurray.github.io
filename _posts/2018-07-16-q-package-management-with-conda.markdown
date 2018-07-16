---
layout: post
title:  "q package management with Anaconda & qutil"
categories: kdb q package qutil anaconda conda
---

One thing I've always envied in other languages is package management. Python
has `pip`, Node.js has `npm`, R has CRAN, ruby has gems...the list goes on. For
a kdb+ dev, the situation is a little different. For a start, there's much less
open source (or closed source, for that matter) code available to be used in
our projects. And when there are bits and pieces available, they're not always
written in a way that easily integrates into other code. We end up copying &
pasting code into our code base, making it trickier to get (or contribute)
upstream changes.

For a while there have existed a few options for easing the pain of loading
other people's code in your project; options such as the excellent [qutil][qutil]
from Dan Nugent. In short, qutil provides a nice, standardised way of packaging
code (i.e. a directory with an `init.q` file), and also a standardised way of
organising & loading these packages (i.e. in a directory pointed to by an env
var, and loading them with `.utl.require` function). There are a couple of
other options ([require.q][require.q], [qpm][qpm]), but I prefer `qutil`.

So that leaves one thing missing that the other languages have; an easy to use
command line installer for packages with a central repo. I had thought for a
while it would be really nice to have such a thing for q packages; I even
toyed with the idea of building such a thing. But when kx [announced][kx] the
availablity of kdb+, jupyterq & embedPy on [Anaconda][anaconda], I realised
that Anaconda (which I had previously thought was "just for python") provided a
cross-platform, language agnostic package manager in the form of `conda`.

So I started packaging some q packages for installation with `conda`. One of
these packages is `qutil` itself, which sets up the package loading code within
the conda environment. Other packages I have packaged are dependent on this, so
you shouldn't have to install it directly, it'll automatically be set up when
you install another package.

I deliberately did _not_ make any of my packages dependent on the kx kdb
package - while this is a nice, easy way to get 64-bit kdb+ up & running, it is
on-demand only & only for Mac & Linux; Anaconda itself works fine on Windows,
and 32-bit (here's hoping that kx add a Windows version soon, and 32-bit). So
the q packages installed in this way will work with either Anaconda kdb or
system kdb (installed via traditional means).



The easiest way to get up & running is to install [miniconda][mc] (a minimal 
Anaconda distribution) and then use `conda install` to install some of my
[packages][pkgs], for example:

{% highlight bash %}
jonny@kodiak ~ $ wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
## allow script to download
jonny@kodiak ~ $ sh Miniconda3-latest-Linux-x86_64.sh
## accept the agreement etc.
jonny@kodiak ~ $ export PATH=/home/jonny/miniconda3/bin:$PATH       # add miniconda to PATH
jonny@kodiak ~ $ source activate base                               # activate base conda env
(base) jonny@kodiak ~ $ conda install -c jmcmurray req              # install reQ package & dependencies
## accept prompt to install
(base) jonny@kodiak ~ $ q                                           # start q & test newly install pkg
KDB+ 3.5 2018.04.25 Copyright (C) 1993-2018 Kx Systems
l64/ 4(16)core 7360MB jonny kodiak 127.0.1.1 EXPIRE 2019.05.21 jonathon.mcmurray@aquaq.co.uk KOD #4160315

q).utl.require"req"
q).req.g"https://httpbin.org/get"
args   | (`symbol$())!()
headers| `Accept`Connection`Host`User-Agent!("*/*";"close";"httpbin.org";"kdb..
origin | "146.199.80.196"
url    | "https://httpbin.org/get"
{% endhighlight %}

Over the next few weeks, I hope to release a bunch more packages, and I really
hope that we are at the beginning of kdb+ going far more mainstream and 
building a much larger open source community, with lots of packages available
for use in our various projects.

I'll post more about creating conda packages for q code in a future blog post,
but for those interested you can check my [conda-recipes][recipes] repo 
containing the "recipes" used to build most of my conda packages.


[qutil]:         https://github.com/nugend/qutil
[require.q]:     https://github.com/BuaBook/kdb-common/wiki/require.q
[qpm]:           https://github.com/yang-guo/qp
[kx]:            https://kx.com/blog/kdb-on-anaconda-and-google-cloud/
[anaconda]:      https://anaconda.org/
[mc]:            https://conda.io/miniconda.html
[pkgs]:          https://anaconda.org/jmcmurray/repo
[recipes]:       https://github.com/jonathonmcmurray/conda-recipes