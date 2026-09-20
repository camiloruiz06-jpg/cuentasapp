// Sube el número de versión cada vez que cambies index.html
var CACHE='mi-reventa-v15';
var SHELL=['./','index.html','manifest.webmanifest','favicon.svg','icon-192.png','icon-512.png','apple-touch-icon.png','supabase.sql'];

self.addEventListener('install',function(e){
  e.waitUntil(caches.open(CACHE).then(function(c){return c.addAll(SHELL);}).then(function(){return self.skipWaiting();}));
});
self.addEventListener('activate',function(e){
  e.waitUntil(caches.keys().then(function(ks){
    return Promise.all(ks.filter(function(k){return k!==CACHE;}).map(function(k){return caches.delete(k);}));
  }).then(function(){return self.clients.claim();}));
});
self.addEventListener('fetch',function(e){
  var r=e.request;
  if(r.method!=='GET')return;
  var u=new URL(r.url);
  var fonts=u.hostname==='fonts.googleapis.com'||u.hostname==='fonts.gstatic.com';
  if(u.origin!==location.origin&&!fonts)return;
  var html=r.mode==='navigate'||u.pathname==='/'||/\.html$/.test(u.pathname);
  e.respondWith(caches.open(CACHE).then(function(c){
    var net=fetch(r).then(function(res){
      if(res&&(res.ok||res.type==='opaque'))c.put(r,res.clone());
      return res;
    });
    if(html)return net.catch(function(){return c.match(r,{ignoreSearch:true});});
    return c.match(r,{ignoreSearch:true}).then(function(hit){
      net.catch(function(){});
      return hit||net.catch(function(){return hit;});
    });
  }));
});
