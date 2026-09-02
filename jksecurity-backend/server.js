const express = require('express');
const cors = require('cors');
const multer = require('multer');
const http = require('http');
const { Server } = require('socket.io');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
  }
});

const PORT = process.env.PORT || 3000;

// ==========================================
// 🔑 SUPABASE CONFIGURATION
// ==========================================
const SUPABASE_URL = 'https://rasmqsrnchugnxwztyhn.supabase.co';
const SUPABASE_KEY = 'sb_publishable_80STflwxIUa5cSUJ3Civ0g_tuDu8oP0';
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
// ==========================================

// Middleware
app.use(cors());
app.use(express.json());

// Configure Multer to keep photo files in memory buffer for direct upload to Supabase
const upload = multer({ storage: multer.memoryStorage() });

// Socket Connection Listener
io.on('connection', (socket) => {
  console.log('Dashboard connected to WebSockets:', socket.id);
  socket.on('disconnect', () => console.log('Dashboard disconnected:', socket.id));
});

// --- ROUTES ---

// GET: Retrieve all reports from Supabase Database
app.get('/api/reports', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('reports')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;

    // Format keys for your Web Dashboard
    const formattedReports = data.map((r) => ({
      id: r.id,
      siteName: r.site_name,
      guardName: r.guard_name,
      supervisor: r.guard_name, // Legacy support for dashboard
      time: r.time,
      type: r.type,
      status: r.status,
      notes: r.notes,
      coordinates: r.coordinates,
      photoUrl: r.photo_url
    }));

    res.json({ success: true, count: formattedReports.length, data: formattedReports });
  } catch (err) {
    console.error('Error fetching reports from Supabase:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST: Receive new guard inspection report, save to Supabase DB & Storage
app.post('/api/reports', (req, res, next) => {
  // Middleware check: Handle multipart/form-data for photo uploads or JSON for raw requests
  if (req.is('multipart/form-data')) {
    upload.single('photo')(req, res, next);
  } else {
    next();
  }
}, async (req, res) => {
  try {
    const { siteName, guardName, supervisor, type, notes, coordinates } = req.body || {};
    const assignedOfficial = guardName || supervisor || 'Field Guard';
    const currentTime = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    let publicPhotoUrl = null;

    // 1. Upload attached photo to Supabase Storage if present
    if (req.file) {
      const fileName = `${Date.now()}-${req.file.originalname}`;
      const { error: storageError } = await supabase.storage
        .from('inspection-photos')
        .upload(fileName, req.file.buffer, {
          contentType: req.file.mimetype,
        });

      if (storageError) throw storageError;

      const { data: urlData } = supabase.storage
        .from('inspection-photos')
        .getPublicUrl(fileName);

      publicPhotoUrl = urlData.publicUrl;
    }

    // 2. Insert record into Supabase PostgreSQL 'reports' table
    const { data: dbData, error: dbError } = await supabase
      .from('reports')
      .insert([
        {
          site_name: siteName || 'Unknown Site',
          guard_name: assignedOfficial,
          time: currentTime,
          type: type || 'Routine Check',
          status: 'Completed',
          notes: notes || 'No extra notes provided.',
          coordinates: coordinates || '-1.286389, 36.817223',
          photo_url: publicPhotoUrl
        }
      ])
      .select();

    if (dbError) throw dbError;

    const newReport = {
      id: dbData[0].id,
      siteName: dbData[0].site_name,
      guardName: dbData[0].guard_name,
      supervisor: dbData[0].guard_name, // Retains supervisor key for dashboard compatibility
      time: dbData[0].time,
      type: dbData[0].type,
      status: dbData[0].status,
      notes: dbData[0].notes,
      coordinates: dbData[0].coordinates,
      photoUrl: dbData[0].photo_url
    };

    // 3. Broadcast real-time update to Web Dashboard
    io.emit('new_report', newReport);

    console.log('New Inspection Report Saved to Supabase & Emitted:', newReport);
    res.status(201).json({ success: true, message: 'Report submitted successfully!', data: newReport });
  } catch (err) {
    console.error('Error submitting report:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// Start HTTP & WebSocket Server
server.listen(PORT, () => {
  console.log(`JK Security Backend running with Supabase on http://localhost:${PORT}`);
});
