const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { MongoClient, ObjectId } = require('mongodb');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3002;

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB connection
let db;
let schedulesCollection;
let timetablePhotosCollection;

// Connect to MongoDB
async function connectToDatabase() {
  try {
    // Use local MongoDB instance
    const mongoUri = 'mongodb://localhost:27017';
    console.log(`Attempting to connect to local MongoDB at: ${mongoUri}`);
    
    const client = new MongoClient(mongoUri);
    
    await client.connect();
    db = client.db('attendance_management');
    schedulesCollection = db.collection('schedules');
    timetablePhotosCollection = db.collection('timetable_photos');
    console.log('Connected to local MongoDB');
  } catch (error) {
    console.error('Failed to connect to local MongoDB:', error);
    process.exit(1);
  }
}

// Add a helper function to convert camelCase to snake_case
function toSnakeCase(obj) {
  if (typeof obj !== 'object' || obj === null) return obj;
  
  if (Array.isArray(obj)) {
    return obj.map(toSnakeCase);
  }
  
  const newObj = {};
  for (const key in obj) {
    if (obj.hasOwnProperty(key)) {
      const snakeKey = key.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
      newObj[snakeKey] = obj[key];
    }
  }
  return newObj;
}

// Add a helper function to convert snake_case to camelCase
function toCamelCase(obj) {
  if (typeof obj !== 'object' || obj === null) return obj;
  
  if (Array.isArray(obj)) {
    return obj.map(toCamelCase);
  }
  
  const newObj = {};
  for (const key in obj) {
    if (obj.hasOwnProperty(key)) {
      const camelKey = key.replace(/_([a-z])/g, (match, letter) => letter.toUpperCase());
      newObj[camelKey] = obj[key];
    }
  }
  return newObj;
}

// Routes for schedules
// Get all schedules for a semester
app.get('/api/schedules/semester/:semester', async (req, res) => {
  try {
    const semester = parseInt(req.params.semester);
    const schedules = await schedulesCollection.find({ semester }).toArray();
    // Convert snake_case to camelCase for the frontend
    const camelCaseSchedules = schedules.map(schedule => toCamelCase(schedule));
    res.json(camelCaseSchedules);
  } catch (error) {
    console.error('Error fetching schedules:', error);
    res.status(500).json({ error: 'Failed to fetch schedules' });
  }
});

// Add a new schedule
app.post('/api/schedules', async (req, res) => {
  try {
    // Convert camelCase to snake_case for the database
    const scheduleData = toSnakeCase(req.body);
    const result = await schedulesCollection.insertOne(scheduleData);
    // Convert back to camelCase for the response
    const responseSchedule = toCamelCase({ ...scheduleData, _id: result.insertedId });
    res.status(201).json(responseSchedule);
  } catch (error) {
    console.error('Error adding schedule:', error);
    res.status(500).json({ error: 'Failed to add schedule' });
  }
});

// Update a schedule
app.put('/api/schedules/:id', async (req, res) => {
  try {
    const id = req.params.id;
    // Convert camelCase to snake_case for the database
    const scheduleData = toSnakeCase(req.body);
    await schedulesCollection.updateOne(
      { _id: new ObjectId(id) },
      { $set: scheduleData }
    );
    res.json({ message: 'Schedule updated successfully' });
  } catch (error) {
    console.error('Error updating schedule:', error);
    res.status(500).json({ error: 'Failed to update schedule' });
  }
});

// Delete a schedule
app.delete('/api/schedules/:id', async (req, res) => {
  try {
    const id = req.params.id;
    await schedulesCollection.deleteOne({ _id: new ObjectId(id) });
    res.json({ message: 'Schedule deleted successfully' });
  } catch (error) {
    console.error('Error deleting schedule:', error);
    res.status(500).json({ error: 'Failed to delete schedule' });
  }
});

// Delete all schedules for a semester
app.delete('/api/schedules/semester/:semester', async (req, res) => {
  try {
    const semester = parseInt(req.params.semester);
    await schedulesCollection.deleteMany({ semester });
    res.json({ message: `All schedules for semester ${semester} deleted successfully` });
  } catch (error) {
    console.error('Error deleting schedules:', error);
    res.status(500).json({ error: 'Failed to delete schedules' });
  }
});

// Routes for timetable photos
// Get timetable photos by department and semester
app.get('/api/timetable-photos/:department/:semester', async (req, res) => {
  try {
    const department = req.params.department;
    const semester = parseInt(req.params.semester);
    const photos = await timetablePhotosCollection.find({
      department_name: department,
      semester
    }).toArray();
    res.json(photos);
  } catch (error) {
    console.error('Error fetching timetable photos:', error);
    res.status(500).json({ error: 'Failed to fetch timetable photos' });
  }
});

// Get all timetable photos
app.get('/api/timetable-photos', async (req, res) => {
  try {
    const photos = await timetablePhotosCollection.find({}).toArray();
    res.json(photos);
  } catch (error) {
    console.error('Error fetching timetable photos:', error);
    res.status(500).json({ error: 'Failed to fetch timetable photos' });
  }
});

// Add a new timetable photo
app.post('/api/timetable-photos', async (req, res) => {
  try {
    const photo = req.body;
    const result = await timetablePhotosCollection.insertOne(photo);
    res.status(201).json({ ...photo, _id: result.insertedId });
  } catch (error) {
    console.error('Error adding timetable photo:', error);
    res.status(500).json({ error: 'Failed to add timetable photo' });
  }
});

// Update a timetable photo
app.put('/api/timetable-photos/:id', async (req, res) => {
  try {
    const id = req.params.id;
    const photo = req.body;
    await timetablePhotosCollection.updateOne(
      { _id: new ObjectId(id) },
      { $set: photo }
    );
    res.json({ message: 'Timetable photo updated successfully' });
  } catch (error) {
    console.error('Error updating timetable photo:', error);
    res.status(500).json({ error: 'Failed to update timetable photo' });
  }
});

// Delete a timetable photo
app.delete('/api/timetable-photos/:id', async (req, res) => {
  try {
    const id = req.params.id;
    await timetablePhotosCollection.deleteOne({ _id: new ObjectId(id) });
    res.json({ message: 'Timetable photo deleted successfully' });
  } catch (error) {
    console.error('Error deleting timetable photo:', error);
    res.status(500).json({ error: 'Failed to delete timetable photo' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Connect to database and start server
connectToDatabase().then(() => {
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
}).catch(error => {
  console.error('Failed to start server:', error);
  process.exit(1);
});