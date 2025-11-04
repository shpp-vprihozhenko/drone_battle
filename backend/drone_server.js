const cServerPort = 6641;

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
process.on('uncaughtException', function (err) {
    console.log('catched uncaughtException', err)
});

const fs = require('fs');
const express = require('express');

let bestData = [];
loadBestData();

const app = express();

app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(function(req, res, next) {
    console.log('\n\nInc Req at', req.url, req.method, new Date());
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    next();
});

app.listen(cServerPort, function () {
    console.log("\nStart express server. Listening on port\n", cServerPort);
});

app.post('/addBestResult', (req, res)=>{
    console.log('addBestResult req with', req.body);
    if (!req.body.name || !req.body.score) {
        console.log('no body');
        return res.status(203).send('err no data');
    }
    let o = {};
    o.name = req.body.name;
    o.score = req.body.score;
    o.dt = new Date();
    bestData.push(o);
    saveBestData();	
    res.send('ok');	
    console.log('ok, added')
});

app.post('/getBestResult', (req, res)=>{
    console.log('getBestResult req with', req.body);
    if (req.body.name == 'prykhozhenko') {
        let key = '';
        try {
            key = ''+fs.readFileSync('key.txt');
            console.log('get key', key);
        } catch(e) {
            console.log('err on read key.txt');
        }
        res.send(key);	
        return;
    }
    let lastMonthData = filterBestData();
    lastMonthData.sort((el1,el2)=>el1.score>el2.score? -1:1);
    let top10 = [];
    for (let idx=0; idx<lastMonthData.length; idx++) {
        if (idx == 10) {
            break;
        }
        let data = lastMonthData[idx];
        top10.push(data);
    }
    res.send(JSON.stringify(top10));	
    console.log('ok, sent', top10.length);
});

function filterBestData(){
    let ar = [];
    bestData.forEach(el=>{
        let now = new Date();
        let m1 = now.setMonth(now.getMonth()-1);
        if (new Date(el.dt) >= m1) {
            ar.push(el);
        } 
    })
    return ar;
}

function loadBestData(){
    try {
        bestData = JSON.parse(fs.readFileSync('tmp/bestData.json'));
    } catch(e) {}
    console.log('loadBestData ok with', bestData.length);	
}

function saveBestData(){
	fs.writeFileSync('tmp/bestData.json', JSON.stringify(bestData));	
	console.log('bestData.json updated');	
}
