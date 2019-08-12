.z.ws:{x} /must set .z.ws to accept WebSocket connections
.pl.h:.h.htac[`script;enlist[`src]!enlist"https://cdn.plot.ly/plotly-latest.min.js";""];
.pl.h,:.h.htc[`script]"ws=new WebSocket('ws://",string[.z.h],":",string[system"p"],"');ws.onmessage=function(x){Plotly.react('kdb-graph',JSON.parse(x.data));};";
.pl.h,:.h.htac[`div;(1#`id)!enlist"kdb-graph";""];
.pl.h:.h.htc[`html;.pl.h];
.z.ph:{.h.hy[`htm].pl.h}

/
q)\l ../../git/settings/kdb-linux/makedb.q
Created quotes table of count 10000 and trades table of count 2000.
Type 'quotes' or 'trades' to view each table.

q)neg[6].j.j 0!select x:time,y:price by name:sym from trades
