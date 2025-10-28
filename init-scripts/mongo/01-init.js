// MongoDB initialization script

// Switch to app_db database
db = db.getSiblingDB('app_db');

// Create development user
db.createUser({
  user: 'dev',
  pwd: 'dev123',
  roles: [
    { role: 'readWrite', db: 'app_db' },
    { role: 'readWrite', db: 'test_db' },
    { role: 'readWrite', db: 'staging_db' }
  ]
});

// Create additional databases
db = db.getSiblingDB('test_db');
db.createCollection('init_collection');

db = db.getSiblingDB('staging_db');
db.createCollection('init_collection');

// Return to app_db and create initial collection
db = db.getSiblingDB('app_db');
db.createCollection('init_collection');

// Create sample indexes for demonstration
db.init_collection.createIndex({ "created_at": 1 });
db.init_collection.createIndex({ "updated_at": 1 }, { expireAfterSeconds: 86400 });

print('MongoDB initialization completed successfully');