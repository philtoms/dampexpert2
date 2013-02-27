createSpy = function(){return function(){}}
require("coffee-script"); 

//require ('./examples/commandrouter.coffee');
require ('./src/mvz.coffee')(3000, function(ready){
  this.zappaCtx = function(){}
  this.include('/tests/includes/includeextension.coffee');
  this.include('/tests/includes/nestedextension');
  //ready();
})
