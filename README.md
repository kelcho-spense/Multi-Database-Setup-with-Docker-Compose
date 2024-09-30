# Multi-Database Setup with Docker Compose

 This README provides clear instructions on running the `setup_databases.sh` script, accessing each database, and understanding the overall project structure. It's designed to be user-friendly and informative, ensuring that anyone interacting with your project can do so with ease.



Certainly! Below are the updated `setup_databases.sh` script **without health checks** and a comprehensive **README** that explains each database in detail. This setup includes **Microsoft SQL Server (MSSQL)**, **MySQL**, **PostgreSQL**, **MongoDB**, and **Redis**.

---

## 1. Updated `setup_databases.sh` Script (Without Health Checks)

This Bash script automates the setup of five databases using Docker Compose. It creates the necessary directory structure, sets fixed passwords, generates initialization scripts, and deploys the containers.

### **⚠️ Security Notice:**
Using the same password across multiple services is **not recommended** for production environments. It's advisable to use unique, strong passwords for each service to enhance security. The current setup uses a fixed password (`YourStrong!Password`) for simplicity and demonstration purposes.

### **Script Content**

Create a file named `setup_databases.sh` and paste the following content:

```bash
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
```

### **Script Explanation**

1. **Dependency Checks:**
   - Verifies that both Docker and Docker Compose are installed.

2. **Directory Structure:**
   - Creates necessary directories for each database's initialization scripts, including Redis.

3. **Environment Variables:**
   - Sets a fixed password (`YourStrong!Password`) for all services.
   - Generates a `.env` file containing these passwords.

4. **Docker Compose Configuration:**
   - Generates a `docker-compose.yml` file defining services for MSSQL, MySQL, PostgreSQL, MongoDB, and Redis.
   - Redis is configured with a password and exposed on port `6379`.

5. **Initialization Scripts:**
   - Creates SQL and JavaScript scripts to set up databases, tables/collections, and insert dummy data for MSSQL, MySQL, PostgreSQL, and MongoDB.
   - Creates a Redis initialization script (`init.sh`) that sets initial key-value pairs. This script is optional and can be customized as needed.

6. **Deployment:**
   - Launches all Docker containers in detached mode using `docker-compose up -d`.

7. **Post-Deployment Information:**
   - Displays the contents of the `.env` file.
   - Shows the status of each container using `docker-compose ps`.
   - Indicates that the setup is complete.

---

## 2. Comprehensive README

Below is a detailed **README** file that explains the project setup, each database, how to run the script, and how to access each database.

---

# Multi-Database Setup with Docker Compose

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Project Structure](#project-structure)
4. [Setup Instructions](#setup-instructions)
   - [1. Clone the Repository](#1-clone-the-repository)
   - [2. Make the Script Executable](#2-make-the-script-executable)
   - [3. Run the Setup Script](#3-run-the-setup-script)
5. [Accessing the Databases](#accessing-the-databases)
   - [1. Microsoft SQL Server (MSSQL)](#1-microsoft-sql-server-mssql)
   - [2. MySQL](#2-mysql)
   - [3. PostgreSQL](#3-postgresql)
   - [4. MongoDB](#4-mongodb)
   - [5. Redis](#5-redis)
6. [Managing the Docker Containers](#managing-the-docker-containers)
   - [Viewing Container Status](#viewing-container-status)
   - [Stopping the Services](#stopping-the-services)
   - [Removing the Services and Volumes](#removing-the-services-and-volumes)
7. [Security Considerations](#security-considerations)
8. [Troubleshooting](#troubleshooting)
9. [Additional Resources](#additional-resources)
10. [License](#license)

---

## Overview

This project automates the setup of five popular databases—**Microsoft SQL Server (MSSQL)**, **MySQL**, **PostgreSQL**, **MongoDB**, and **Redis**—using **Docker Compose**. A Bash script (`setup_databases.sh`) orchestrates the setup process, ensuring that all databases are configured with a consistent schema (`todo_db` with a `todo_table`) and populated with dummy data for immediate use.

---

## Prerequisites

Before getting started, ensure that your system meets the following requirements:

- **Operating System:** Unix-like systems (Linux, macOS). Windows users can use **WSL** (Windows Subsystem for Linux) or a compatible terminal emulator.
- **Docker:** [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose:** [Install Docker Compose](https://docs.docker.com/compose/install/)
- **Bash Shell:** Typically available by default on Unix-like systems.

### Verify Installations

Open your terminal and run the following commands to verify that Docker and Docker Compose are installed:

```bash
docker --version
docker-compose --version
bash --version
```

You should see version information for each command. If any are missing, refer to the provided installation links.

---

## Project Structure

Here's an overview of the project's directory structure:

```
your-project/
├── docker-compose.yml
├── setup_databases.sh
├── .env
├── .gitignore
├── mssql/
│   └── init/
│       └── init.sql
├── mysql/
│   └── init/
│       └── init.sql
├── postgres/
│   └── init/
│       └── init.sql
├── mongodb/
│   └── init/
│       └── init.js
└── redis/
    └── init/
        └── init.sh
```

- **docker-compose.yml:** Defines the services for MSSQL, MySQL, PostgreSQL, MongoDB, and Redis.
- **setup_databases.sh:** Bash script to automate the setup process.
- **.env:** Stores environment variables, including database passwords.
- **.gitignore:** Specifies files to be ignored by Git (e.g., `.env`).
- **`<db>/init/`:** Contains initialization scripts for each respective database.

---

## Setup Instructions

Follow these steps to set up your multi-database environment.

### 1. Clone the Repository

If you haven't already, clone your project repository to your local machine:

```bash
git clone https://github.com/your-username/your-project.git
cd your-project
```

*Replace `your-username` and `your-project` with your actual GitHub username and repository name.*

### 2. Make the Script Executable

Ensure that the `setup_databases.sh` script has executable permissions:

```bash
chmod +x setup_databases.sh
```

### 3. Run the Setup Script

Execute the script to initialize the databases:

```bash
./setup_databases.sh
```

**What the Script Does:**

1. **Dependency Checks:** Verifies that Docker and Docker Compose are installed.
2. **Directory Creation:** Sets up necessary directories for initialization scripts.
3. **Environment Variables:** Creates a `.env` file with fixed passwords (`YourStrong!Password`).
4. **Initialization Scripts:** Generates SQL and JavaScript files to set up databases, tables/collections, and insert dummy data. Additionally, it creates a Redis initialization script to set initial key-value pairs.
5. **Docker Compose Configuration:** Creates a `docker-compose.yml` file configured to use the `.env` variables.
6. **Deployment:** Launches all Docker containers in detached mode.
7. **Display Information:** Shows the contents of the `.env` file and the status of each container.
8. **Completion Message:** Indicates that the setup is complete.

**Note:** The script uses a fixed password (`YourStrong!Password`) for all services. For security reasons, especially in production environments, it's recommended to use unique, strong passwords for each service.

---

## Accessing the Databases

Once the setup script completes successfully, all databases will be running and accessible on your local machine through their respective ports. Below are instructions on how to connect to each database using command-line tools.

### 1. Microsoft SQL Server (MSSQL)

**Connection Details:**

- **Host:** `localhost`
- **Port:** `1433`
- **User:** `SA`
- **Password:** `YourStrong!Password`
- **Database:** `todo_db`

**Accessing via `sqlcmd`:**

```bash
docker exec -it db-mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'YourStrong!Password'
```

**Within `sqlcmd`:**

```sql
USE todo_db;
GO
SELECT * FROM dbo.todo_table;
GO
```

### 2. MySQL

**Connection Details:**

- **Host:** `localhost`
- **Port:** `3306`
- **User:** `admin`
- **Password:** `YourStrong!Password`
- **Database:** `todo_db`

**Accessing via `mysql`:**

```bash
docker exec -it db-mysql mysql -uadmin -pYourStrong!Password todo_db
```

**Within MySQL Shell:**

```sql
SELECT * FROM todo_table;
```

### 3. PostgreSQL

**Connection Details:**

- **Host:** `localhost`
- **Port:** `5432`
- **User:** `admin`
- **Password:** `YourStrong!Password`
- **Database:** `todo_db`

**Accessing via `psql`:**

```bash
docker exec -it db-postgres psql -U admin -d todo_db
```

**Within `psql`:**

```sql
SELECT * FROM todo_table;
```

### 4. MongoDB

**Connection Details:**

- **Host:** `localhost`
- **Port:** `27017`
- **User:** `admin`
- **Password:** `YourStrong!Password`
- **Database:** `todo_db`

**Accessing via Mongo Shell:**

```bash
docker exec -it db-mongodb mongo -u admin -p YourStrong!Password --authenticationDatabase admin todo_db
```

**Within Mongo Shell:**

```javascript
db.todo_table.find().pretty();
```

### 5. Redis

**Connection Details:**

- **Host:** `localhost`
- **Port:** `6379`
- **Password:** `YourStrong!Password`

**Accessing via `redis-cli`:**

1. **Enter the Redis Container:**

   ```bash
   docker exec -it db-redis bash
   ```

2. **Connect to Redis:**

   ```bash
   redis-cli -a YourStrong!Password
   ```

**Within Redis CLI:**

```redis
PING
# Expected Response: PONG

GET welcome
# Expected Response: "Welcome to Redis!"

GET task1
# Expected Response: "Buy groceries"

GET task2
# Expected Response: "Complete project report"

GET task3
# Expected Response: "Call the bank"

GET task4
# Expected Response: "Schedule dentist appointment"
```

**Note:** The Redis initialization script (`redis/init/init.sh`) sets some initial key-value pairs for demonstration purposes. You can customize this script to add more keys or perform other initialization tasks as needed.

---

## Managing the Docker Containers

### Viewing Container Status

To check the status of all running containers:

```bash
docker-compose ps
```

**Sample Output:**

```
      Name                    Command               State                  Ports
------------------------------------------------------------------------------------------
your-project_db-mssql_1   /opt/mssql/bin/sqlservr      Up      0.0.0.0:1433->1433/tcp
your-project_db-mysql_1    docker-entrypoint.sh mysqld   Up      0.0.0.0:3306->3306/tcp
your-project_db-postgres_1 docker-entrypoint.sh postgres   Up      0.0.0.0:5432->5432/tcp
your-project_db-mongodb_1  docker-entrypoint.sh mongod    Up      0.0.0.0:27017->27017/tcp
your-project_db-redis_1    redis-server --requirep...    Up      0.0.0.0:6379->6379/tcp
```

### Stopping the Services

To stop all running containers without removing them:

```bash
docker-compose stop
```

### Removing the Services and Volumes

**⚠️ Warning:** This action will **delete all data** stored in the databases.

To stop and remove all containers, networks, and volumes:

```bash
docker-compose down -v
```

---

## Security Considerations

- **Fixed Passwords:** The setup uses a fixed password (`YourStrong!Password`) for all services. **Avoid using the same password across multiple services in production environments.** Consider modifying the `setup_databases.sh` script to generate unique, strong passwords.

- **Protect `.env` File:**
  - Ensure that the `.env` file is **never** committed to version control systems. It's already included in `.gitignore`, but double-check to confirm.
  - **Additional Protection:** Limit file permissions to restrict access:

    ```bash
    chmod 600 .env
    ```

- **Network Security:**
  - The databases are exposed on standard ports (`1433`, `3306`, `5432`, `27017`, `6379`) accessible from `localhost`. For production, consider using Docker networks to isolate services and avoid exposing ports publicly.

- **Docker Secrets (Advanced):**
  - For enhanced security, especially in production, use [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/) to manage sensitive information instead of environment variables.

---

## Troubleshooting

If you encounter issues during setup or while accessing the databases, follow these steps:

### 1. Check Container Logs

View logs for a specific service to identify issues:

```bash
docker-compose logs [service-name]
```

*Replace `[service-name]` with `db-mssql`, `db-mysql`, `db-postgres`, `db-mongodb`, or `db-redis`.*

**Example:**

```bash
docker-compose logs db-mysql
```

### 2. Ensure Services Are Running

Verify that all services are up and running:

```bash
docker-compose ps
```

Ensure that each service is listed as `Up`.

### 3. Common Issues

- **Password Complexity:** Ensure that the password (`YourStrong!Password`) meets the complexity requirements of each database. For MSSQL, it must be at least 8 characters and include uppercase, lowercase, numbers, and symbols.

- **Port Conflicts:** Verify that the required ports are not in use by other applications:

  ```bash
  sudo lsof -i -P -n | grep LISTEN
  ```

  If a port is in use, stop the conflicting service or modify the `docker-compose.yml` to use a different port.

- **Resource Limits:** Ensure your system has sufficient CPU and memory resources to run all containers.

- **Initialization Scripts Not Running:**
  - Confirm that the initialization scripts are correctly placed in their respective `init` directories.
  - Verify the syntax and content of the scripts to ensure they execute without errors.

### 4. Restarting Services

Sometimes, restarting a service can resolve issues:

```bash
docker-compose restart [service-name]
```

*Example:*

```bash
docker-compose restart db-postgres
```

---

## Additional Resources

- **Docker Documentation:** [https://docs.docker.com/](https://docs.docker.com/)
- **Docker Compose Documentation:** [https://docs.docker.com/compose/](https://docs.docker.com/compose/)
- **MSSQL Docker Image:** [https://hub.docker.com/_/microsoft-mssql-server](https://hub.docker.com/_/microsoft-mssql-server)
- **MySQL Docker Image:** [https://hub.docker.com/_/mysql](https://hub.docker.com/_/mysql)
- **PostgreSQL Docker Image:** [https://hub.docker.com/_/postgres](https://hub.docker.com/_/postgres)
- **MongoDB Docker Image:** [https://hub.docker.com/_/mongo](https://hub.docker.com/_/mongo)
- **Redis Docker Image:** [https://hub.docker.com/_/redis](https://hub.docker.com/_/redis)
- **Bash Scripting Guide:** [https://www.gnu.org/software/bash/manual/bash.html](https://www.gnu.org/software/bash/manual/bash.html)

---

## License

This project is licensed under the [MIT License](LICENSE).

---

# Contact

For questions, issues, or contributions, please open an issue on the [GitHub repository](https://github.com/kelcho-spense/Multi-Database-Setup-with-Docker-Compose/issues) or contact [linkedin](https://www.linkedin.com/in/kevin-comba-gatimu/)).

---
