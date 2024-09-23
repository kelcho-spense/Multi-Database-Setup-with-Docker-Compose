#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to check if a command exists
command_exists () {
    command -v "$1" >/dev/null 2>&1
}

# Check for Docker
if ! command_exists docker ; then
    echo "Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check for Docker Compose
if ! command_exists docker-compose ; then
    echo "Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Define project directory
PROJECT_DIR=$(pwd)

# Create necessary directories
echo "Creating directory structure..."
mkdir -p mssql/init
mkdir -p mysql/init
mkdir -p postgres/init
mkdir -p mongodb/init
mkdir -p redis/init

# Set fixed passwords
echo "Setting fixed passwords..."
FIXED_PASSWORD="YourStrong!Password"

MSSQL_SA_PASSWORD="${FIXED_PASSWORD}"
MYSQL_ROOT_PASSWORD="${FIXED_PASSWORD}"
MYSQL_USER_PASSWORD="${FIXED_PASSWORD}"
POSTGRES_PASSWORD="${FIXED_PASSWORD}"
MONGODB_ROOT_PASSWORD="${FIXED_PASSWORD}"
REDIS_PASSWORD="${FIXED_PASSWORD}"

# Create .env file
echo "Creating .env file..."
cat > .env <<EOL
MSSQL_SA_PASSWORD=${MSSQL_SA_PASSWORD}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_USER_PASSWORD=${MYSQL_USER_PASSWORD}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
MONGODB_ROOT_PASSWORD=${MONGODB_ROOT_PASSWORD}
REDIS_PASSWORD=${REDIS_PASSWORD}
EOL

# Create docker-compose.yml
echo "Creating docker-compose.yml..."
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  mssql:
    image: mcr.microsoft.com/mssql/server:2019-latest
    environment:
      SA_PASSWORD: "${MSSQL_SA_PASSWORD}"
      ACCEPT_EULA: "Y"
    ports:
      - "1433:1433"
    volumes:
      - mssql-data:/var/opt/mssql
      - ./mssql/init:/init
    networks:
      - db-network
    restart: unless-stopped

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: "${MYSQL_ROOT_PASSWORD}"
      MYSQL_DATABASE: todo_db
      MYSQL_USER: admin
      MYSQL_PASSWORD: "${MYSQL_USER_PASSWORD}"
    ports:
      - "3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql
      - ./mysql/init:/docker-entrypoint-initdb.d
    networks:
      - db-network
    restart: unless-stopped

  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_DB: todo_db
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./postgres/init:/docker-entrypoint-initdb.d
    networks:
      - db-network
    restart: unless-stopped

  mongodb:
    image: mongo:6.0
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: "${MONGODB_ROOT_PASSWORD}"
      MONGO_INITDB_DATABASE: todo_db
    ports:
      - "27017:27017"
    volumes:
      - mongodb-data:/data/db
      - ./mongodb/init:/docker-entrypoint-initdb.d
    networks:
      - db-network
    restart: unless-stopped

  redis:
    image: redis:7.0
    command: ["redis-server", "--requirepass", "${REDIS_PASSWORD}"]
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
      - ./redis/init:/docker-entrypoint-initdb.d
    networks:
      - db-network
    restart: unless-stopped

networks:
  db-network:
    driver: bridge

volumes:
  mssql-data:
  mysql-data:
  postgres-data:
  mongodb-data:
  redis-data:
EOF

# Create MSSQL initialization script
echo "Creating MSSQL initialization script..."
cat > mssql/init/init.sql <<EOL
-- init.sql for MSSQL

-- Wait for the SQL Server to be ready
WAITFOR DELAY '00:00:10';

-- Create Database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'todo_db')
BEGIN
    CREATE DATABASE todo_db;
END
GO

USE todo_db;
GO

-- Create Table
IF OBJECT_ID('dbo.todo_table', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.todo_table (
        id INT IDENTITY(1,1) PRIMARY KEY,
        task NVARCHAR(255) NOT NULL,
        completed BIT DEFAULT 0,
        created_at DATETIME DEFAULT GETDATE()
    );
END
GO

-- Insert Dummy Data
INSERT INTO dbo.todo_table (task, completed)
VALUES 
    ('Buy groceries', 0),
    ('Complete project report', 1),
    ('Call the bank', 0),
    ('Schedule dentist appointment', 0);
GO
EOL

# Create MySQL initialization script
echo "Creating MySQL initialization script..."
cat > mysql/init/init.sql <<EOL
-- init.sql for MySQL

-- Create Database
CREATE DATABASE IF NOT EXISTS todo_db;
USE todo_db;

-- Create Table
CREATE TABLE IF NOT EXISTS todo_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task VARCHAR(255) NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert Dummy Data
INSERT INTO todo_table (task, completed) VALUES
('Buy groceries', FALSE),
('Complete project report', TRUE),
('Call the bank', FALSE),
('Schedule dentist appointment', FALSE);
EOL

# Create PostgreSQL initialization script
echo "Creating PostgreSQL initialization script..."
cat > postgres/init/init.sql <<'EOL'
-- init.sql for PostgreSQL

-- Create Table
CREATE TABLE IF NOT EXISTS todo_table (
    id SERIAL PRIMARY KEY,
    task VARCHAR(255) NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert Dummy Data
INSERT INTO todo_table (task, completed) VALUES
('Buy groceries', FALSE),
('Complete project report', TRUE),
('Call the bank', FALSE),
('Schedule dentist appointment', FALSE);
EOL

# Create MongoDB initialization script
echo "Creating MongoDB initialization script..."
cat > mongodb/init/init.js <<EOL
// init.js for MongoDB

db = db.getSiblingDB('todo_db');

// Create Collection
db.createCollection('todo_table');

// Insert Dummy Data
db.todo_table.insertMany([
    {
        task: 'Buy groceries',
        completed: false,
        created_at: new Date()
    },
    {
        task: 'Complete project report',
        completed: true,
        created_at: new Date()
    },
    {
        task: 'Call the bank',
        completed: false,
        created_at: new Date()
    },
    {
        task: 'Schedule dentist appointment',
        completed: false,
        created_at: new Date()
    }
]);
EOL

# Create Redis initialization script (optional)
echo "Creating Redis initialization script..."
cat > redis/init/init.sh <<EOL
#!/bin/bash
# init.sh for Redis

# Wait for Redis to be ready
sleep 10

# Set initial keys (optional)
redis-cli -a "${REDIS_PASSWORD}" set welcome "Welcome to Redis!"
redis-cli -a "${REDIS_PASSWORD}" set task1 "Buy groceries"
redis-cli -a "${REDIS_PASSWORD}" set task2 "Complete project report"
redis-cli -a "${REDIS_PASSWORD}" set task3 "Call the bank"
redis-cli -a "${REDIS_PASSWORD}" set task4 "Schedule dentist appointment"
EOL

# Make the Redis initialization script executable
chmod +x redis/init/init.sh

# Start Docker Compose
echo "Starting Docker Compose services..."
docker-compose up -d

echo "All services are up and running!"

# Display .env file content (optional)
echo
echo "=== .env File ==="
cat .env
echo "=================="
echo

# Display container statuses
docker-compose ps

echo "Setup complete!"
