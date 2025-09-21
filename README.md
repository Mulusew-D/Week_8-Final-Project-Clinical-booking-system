# Week_8-Final-Project-Clinical-booking-system
# Clinic Booking System Database (MySQL)

This project contains a **relational database schema** for a Clinic Booking System, designed in MySQL.  
It covers Patients, Doctors, Appointments, Prescriptions, Payments, and more, with proper constraints and relationships.

---

## 📋 Objective
- Design and implement a full-featured relational database using **MySQL**.
- Apply **Primary/Foreign Keys**, **Constraints**, **Relationships**, **Indexes**, and **Triggers** for real-world use cases.

---

## 📂 Deliverables
- **`clinic_booking_db.sql`** file containing:
  - `CREATE DATABASE`
  - `CREATE TABLE`
  - Relationships & constraints
  - Indexes & triggers
  - Sample seed data

---

## 🏗 Schema Highlights
- **One-to-One:** Appointments → Payments / Medical Records  
- **One-to-Many:** Patients → Appointments, Doctors → Appointments  
- **Many-to-Many:** Doctors ↔ Specializations  
- **Constraints:**  
  - `PRIMARY KEY`, `FOREIGN KEY`  
  - `NOT NULL`, `UNIQUE`  
  - `ENUM` types for status fields  
- **Triggers:** Prevent overlapping appointments for same doctor/patient  

---

## 📊 Entity-Relationship (ER) Overview
**Entities:**  
- Roles, Users, Departments, Doctors, Specializations  
- Patients, Insurances, Rooms  
- Appointments, Prescriptions, Medications  
- Payments, Medical Records, Audit Logs  

**Relationships:**  
- Patients → Appointments (1:M)  
- Doctors → Appointments (1:M)  
- Doctors ↔ Specializations (M:N)  
- Appointments → Payments (1:1)  
- Appointments → Medical_Records (1:1)


```bash
mysql -u root -p < clinic_booking_db.sql
