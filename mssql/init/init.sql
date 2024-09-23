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
