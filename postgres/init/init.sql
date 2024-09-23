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
