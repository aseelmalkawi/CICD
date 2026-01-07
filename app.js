// Import express module
const express = require('express');

// Create an instance of express
const app = express();

// Define a route to handle GET requests to the root URL
app.get('/', (req, res) => {
  res.send('Hi DevOps ');
});

// Define the port number
const port = 3000;

console.log(`Hello World from Ayat! is now appearing in the browser !!`);

// Start the server and listen on the specified port
app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});

