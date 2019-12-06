const bodyParser = require('body-parser');
const express = require('express');
const app = express();
const listeningPort = 3000;

app.use(bodyParser.json());
app.use(express.static(__dirname + '/public'));

app.listen(listeningPort, () => {
    console.log('Express: listening on port: ' + listeningPort);
})

app.get('/', (req, res) => {
    res.send('Express: Hello from server');
});

app.post('/hello', (req, res) => {
    let body = req.body;
    body.message = 'Hello ' + body.name;
    res.json(body);
});