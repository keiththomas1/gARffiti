var express = require('express'),
  app = express(),
  port = process.env.PORT || 3000,
  mongoose = require('mongoose'),
  Task = require('./api/models/locationModel'), //created model loading here
  bodyParser = require('body-parser'),
  RateLimit = require('express-rate-limit');

// mongoose instance connection url connection
mongoose.Promise = global.Promise;
mongoose.connect(
  'mongodb+srv://keith:iR9F2Pke4Lio3P1L@cluster0-qztnj.mongodb.net/test?retryWrites=true');
  //'mongodb://keith:iR9F2Pke4Lio3P1L@cluster0-shard-00-00-qztnj.mongodb.net:27017,cluster0-shard-00-01-qztnj.mongodb.net:27017,cluster0-shard-00-02-qztnj.mongodb.net:27017/test?ssl=true&replicaSet=Cluster0-shard-0&authSource=admin&retryWrites=true');
app.use(bodyParser.urlencoded({limit: '50mb', extended: true}));
app.use(bodyParser.json({limit: '50mb', extended: true}));
app.enable('trust proxy'); // Since we are behind a reverse proxy (Amazon EBS)

var postLimiter = new RateLimit({
  windowMs: 10*60*1000, // 15 minutes
  max: 100, // limit each IP to 10 requests per windowMs
  delayMs: 0 // disable delaying - full speed until the max limit is reached
});

var locationRoutes = require('./api/routes/locationRoutes'); //importing route
locationRoutes(app); //register the route

app.listen(port);
app.use(postLimiter);

console.log('AR Graffiti\'s awesome server started on port ' + port);
