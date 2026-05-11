const http = require('http');
const url = require('url');
const fs = require('fs');
const path = require('path');

// In-memory Stores
let patients = [];
let appointments = [];
let notifications = [];
let prescriptions = [];

const PORT = 8080;
const DASHBOARD_DIR = path.join(__dirname, 'dashboard');

const server = http.createServer((req, res) => {
    // CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', '*');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    const parsedUrl = url.parse(req.url, true);
    const pathname = parsedUrl.pathname;

    // Serve Static Dashboard Files
    if (pathname === '/' || pathname === '/index.html' || pathname === '/user.html') {
        const file = pathname === '/' ? 'index.html' : pathname.substring(1);
        const filePath = path.join(DASHBOARD_DIR, file);
        fs.readFile(filePath, (err, content) => {
            if (err) {
                res.writeHead(404);
                res.end('File not found');
            } else {
                const ext = path.extname(file);
                const contentType = ext === '.html' ? 'text/html' : 'text/plain';
                res.writeHead(200, { 'Content-Type': contentType });
                res.end(content);
            }
        });
        return;
    }

    // API Routes
    if (pathname === '/auth/token' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ token: "mock-jwt-token-active" }));
        return;
    }

    // Patient Service
    if (pathname === '/patient-service/patients') {
        if (req.method === 'GET') {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(patients));
        } else if (req.method === 'POST') {
            let body = '';
            req.on('data', chunk => { body += chunk.toString(); });
            req.on('end', () => {
                try {
                const patient = JSON.parse(body);
                patient.id = patients.length + 1;
                patients.push(patient);
                res.writeHead(201, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify(patient));
                } catch(e) { res.writeHead(400); res.end(); }
            });
        }
        return;
    }

    if (pathname.startsWith('/patient-service/patients/') && req.method === 'GET') {
        const id = pathname.split('/').pop();
        const patient = patients.find(p => p.id == id);
        if (patient) {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(patient));
        } else {
            res.writeHead(404); res.end();
        }
        return;
    }

    // Appointment Service
    if (pathname === '/appointment-service/appointments') {
        if (req.method === 'GET') {
            const pid = parsedUrl.query.patientId;
            let list = appointments;
            if (pid) list = appointments.filter(a => a.patientId == pid);
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(list));
        } else if (req.method === 'POST') {
            let body = '';
            req.on('data', chunk => { body += chunk.toString(); });
            req.on('end', () => {
                try {
                const appt = JSON.parse(body);
                appt.id = appointments.length + 1;
                appt.status = 'REQUESTED';
                appointments.push(appt);
                res.writeHead(201, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify(appt));
                } catch(e) { res.writeHead(400); res.end(); }
            });
        }
        return;
    }

    if (pathname.startsWith('/appointment-service/appointments/') && pathname.endsWith('/confirm')) {
        const id = pathname.split('/')[3];
        const appt = appointments.find(a => a.id == id);
        if (appt) {
            appt.status = 'CONFIRMED';
            notifications.push({
                id: notifications.length + 1,
                patientId: appt.patientId,
                message: `Your appointment (ID: ${appt.id}) has been confirmed.`,
                sentDate: new Date().toLocaleString()
            });
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(appt));
        } else {
            res.writeHead(404); res.end();
        }
        return;
    }

    // Prescription Service
    if (pathname === '/prescription-service/prescriptions') {
        if (req.method === 'GET') {
            const pid = parsedUrl.query.patientId;
            let list = prescriptions;
            if (pid) list = prescriptions.filter(p => p.patientId == pid);
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(list));
        } else if (req.method === 'POST') {
            let body = '';
            req.on('data', chunk => { body += chunk.toString(); });
            req.on('end', () => {
                try {
                const pr = JSON.parse(body);
                const patient = patients.find(p => p.id == pr.patientId);
                pr.id = Date.now();
                if (!patient) pr.medicine += " (FALLBACK: No patient)";
                prescriptions.push(pr);
                res.writeHead(201, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify(pr));
                } catch(e) { res.writeHead(400); res.end(); }
            });
        }
        return;
    }

    // Notification Service
    if (pathname === '/notification-service/notifications') {
        const pid = parsedUrl.query.patientId;
        let list = notifications;
        if (pid) list = notifications.filter(n => n.patientId == pid);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(list));
        return;
    }

    res.writeHead(404);
    res.end();
});

server.listen(PORT, () => {
    console.log(`Medical MSA Mock Server running at http://localhost:${PORT}`);
    console.log(`Ready to test with Dashboard UI!`);
});
