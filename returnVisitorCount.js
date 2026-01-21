console.log("Javascript file loaded: returnVisitorCounter.js");

const visitorCounter = document.getElementById("visitorCount");
visitorCounter.innerHTML = "This proves that the Script is able to change the section in HTML file using the ID selector."

fetch("https://jsonplaceholder.typicode.com/")
.then(response => response.text())
.then(data => {console.log(data);
}); 