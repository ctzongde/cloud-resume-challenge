console.log("Javascript file loaded: returnVisitorCounter.js");

const visitorCounter = document.getElementById("visitorCount");

// fetch the visitor count from the API invoke URL that would return a promise
fetch("https://u0ulp8txth.execute-api.ap-southeast-1.amazonaws.com/count")
// open the response as json 
.then(Response => Response.json())
// set the innerHTML of the visitorCounter element to the count value from the json response
.then(data => {visitorCounter.innerHTML = data.count + " visitors have visited this resume.";
     console.log(data.count + " visitors have visited this resume.");})
// catch errors and log them to the console
.catch(error => console.error("Error fetching visitor count:", error));