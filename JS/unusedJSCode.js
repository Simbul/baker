// document.onload = function () {
//        document.location = "laresponse:event:page_loaded";
// }

// // 1:

// var img = document.createElement('img');
// img.onerror = function(){
//     document.location = "laresponse:event:event_from_js";
// }
// img.src = url;

// // 2:

// link.onreadystatechange = function() {
//     var state = link.readyState;
//     if (state === 'loaded' || state === 'complete') {
//       link.onreadystatechange = null;
//       document.location = "laresponse:event:event_from_js";
//     }
// };

// // 3:

// if (link.addEventListener) {
//   link.addEventListener('load', function() { 
//       document.location = "laresponse:event:event_from_js";
//   }, false);
// }

// // 4:

// link.onload = function () {
//        document.location = "laresponse:event:event_from_js";
// }