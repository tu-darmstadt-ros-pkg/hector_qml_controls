.pragma library

// Taken from https://stackoverflow.com/questions/105034/how-to-create-guid-uuid
// The faster method does not work because for some reason anything greater than 0.5 times the maximum of a 32 bit unsigned int is 0
// leading to a lot of duplicates
function generate()
{
  var u='',i=0;
  while(i++<36) {
    var c='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'[i-1],r=Math.random()*16|0,v=c=='x'?r:(r&0x3|0x8);
    u+=(c=='-'||c=='4')?c:v.toString(16)
  }
  return u;
}