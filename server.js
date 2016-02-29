require('coffee-script/register');
var express = require('express')
    , https = require('https')
    , fs = require('fs')
    , app = express();

var options = {
  key: fs.readFileSync('./certs/myserver.key'),
  cert: fs.readFileSync('./certs/tryscrap_com.crt')
}

port = 443
server = https.createServer(options, app);
server.listen(port);

var io = require('socket.io')(server)
    , sharedsession = require("express-socket.io-session")
    , db = require('./models');
    // , SequelizeStore = require('connect-session-sequelize')(express.session.Store)

var pg = require('pg')
  , express_session = require('express-session')
  , pgSession = require('connect-pg-simple')(express_session);

var session = express_session({
  store: new pgSession({
    pg : pg, // Use global pg-module
    conString : process.env.POSTGRES_URL || 'postgres://joelsimon@localhost/scrapdb',
  }),
  saveUninitialized: false,
  secret: "club_sexdungeon",
  resave: true,
  cookie: { maxAge: 30 * 24 * 60 * 60 * 1000 } // 30 days
})

app.configure(function(){
    app.set('views', __dirname + '/views');
    app.set("view engine", "jade");
    app.set('view options', { layout: false });
    app.use(express.static(__dirname + '/client'));
    app.use(express.bodyParser());
    app.use(express.cookieParser());
    app.use(session)
    app.use(require('coffee-middleware')({
        src: __dirname + '/client',
        compress: true,
        encodeSrc: false,
        force: true,
        debug: false,
        bare: true
    }));
});

io.use(sharedsession(session));

//{ force: false }
db.sequelize.sync().complete(function(err) {
    if (err) {
        throw err;
    } else {
        require('./server/socketListeners')(io);
        require('./server/routes')(app);
        console.log('Listening on port:' + port );
    }
});
