-- clinic_booking_db.sql
CREATE DATABASE ClinicBookingDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE ClinicBookingDB;

-- ===================================================================
-- Core lookup/reference tables
-- ===================================================================

CREATE TABLE Roles (
  role_id INT AUTO_INCREMENT PRIMARY KEY,
  role_name VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Departments (
  department_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Specializations (
  specialization_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===================================================================
-- Users (system users) and staff / doctors
-- ===================================================================

CREATE TABLE Users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(80) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  email VARCHAR(150) UNIQUE,
  role_id INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_user_role FOREIGN KEY (role_id)
    REFERENCES Roles(role_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE Doctors (
  doctor_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  email VARCHAR(150) UNIQUE,
  phone VARCHAR(30) UNIQUE,
  license_no VARCHAR(80) UNIQUE,
  department_id INT,
  status ENUM('Active','Inactive','On Leave') NOT NULL DEFAULT 'Active',
  hire_date DATE,
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_doctor_department FOREIGN KEY (department_id)
    REFERENCES Departments(department_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Many-to-Many: Doctors <-> Specializations
CREATE TABLE Doctor_Specializations (
  doctor_id INT NOT NULL,
  specialization_id INT NOT NULL,
  PRIMARY KEY (doctor_id, specialization_id),
  CONSTRAINT fk_ds_doctor FOREIGN KEY (doctor_id)
    REFERENCES Doctors(doctor_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ds_specialization FOREIGN KEY (specialization_id)
    REFERENCES Specializations(specialization_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- index helpful for searching doctors by last name
CREATE INDEX idx_doctors_lastname ON Doctors(last_name);

-- ===================================================================
-- Patients, Insurances, Rooms
-- ===================================================================

CREATE TABLE Insurances (
  insurance_id INT AUTO_INCREMENT PRIMARY KEY,
  provider_name VARCHAR(150) NOT NULL,
  policy_number VARCHAR(100) NOT NULL UNIQUE,
  contact_phone VARCHAR(50),
  contact_email VARCHAR(150)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Patients (
  patient_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  date_of_birth DATE NOT NULL,
  gender ENUM('Male','Female','Other') NOT NULL,
  phone VARCHAR(30) UNIQUE,
  email VARCHAR(150) UNIQUE,
  address TEXT,
  insurance_id INT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_patient_insurance FOREIGN KEY (insurance_id)
    REFERENCES Insurances(insurance_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_patients_name ON Patients(last_name, first_name);
CREATE INDEX idx_patients_phone ON Patients(phone);

CREATE TABLE Rooms (
  room_id INT AUTO_INCREMENT PRIMARY KEY,
  room_number VARCHAR(20) NOT NULL UNIQUE,
  room_type ENUM('Consultation','Procedure','Lab','Other') NOT NULL DEFAULT 'Consultation',
  floor INT,
  notes TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===================================================================
-- Appointments (with constraints & basic anti-overlap triggers)
-- ===================================================================

CREATE TABLE Appointments (
  appointment_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  doctor_id INT NOT NULL,
  room_id INT,
  scheduled_start DATETIME NOT NULL,
  scheduled_end DATETIME NOT NULL,
  status ENUM('Scheduled','Completed','Cancelled','No-Show') NOT NULL DEFAULT 'Scheduled',
  reason VARCHAR(255),
  created_by_user_id INT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_appointment_patient FOREIGN KEY (patient_id)
    REFERENCES Patients(patient_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_appointment_doctor FOREIGN KEY (doctor_id)
    REFERENCES Doctors(doctor_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_appointment_room FOREIGN KEY (room_id)
    REFERENCES Rooms(room_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_appointment_creator FOREIGN KEY (created_by_user_id)
    REFERENCES Users(user_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Prevent exact same start for the same doctor or same patient (slot-level uniqueness)
CREATE UNIQUE INDEX ux_doctor_start ON Appointments(doctor_id, scheduled_start);
CREATE UNIQUE INDEX ux_patient_start ON Appointments(patient_id, scheduled_start);

-- Indexes to speed schedule lookups
CREATE INDEX idx_appointments_doctor_start ON Appointments(doctor_id, scheduled_start);
CREATE INDEX idx_appointments_patient_start ON Appointments(patient_id, scheduled_start);

-- ===================================================================
-- Prescriptions, Medications and items (many-to-many)
-- ===================================================================

CREATE TABLE Prescriptions (
  prescription_id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT NOT NULL,
  prescribed_by_doctor_id INT NOT NULL,
  prescribed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notes TEXT,
  CONSTRAINT fk_prescription_appointment FOREIGN KEY (appointment_id)
    REFERENCES Appointments(appointment_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_prescription_doctor FOREIGN KEY (prescribed_by_doctor_id)
    REFERENCES Doctors(doctor_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Medications (
  medication_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  generic_name VARCHAR(200),
  dosage_form VARCHAR(100),
  strength VARCHAR(100),
  manufacturer VARCHAR(150),
  UNIQUE KEY ux_medication_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Prescription_Items (
  prescription_item_id INT AUTO_INCREMENT PRIMARY KEY,
  prescription_id INT NOT NULL,
  medication_id INT NOT NULL,
  dosage VARCHAR(100) NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  instructions TEXT,
  CONSTRAINT fk_pi_prescription FOREIGN KEY (prescription_id)
    REFERENCES Prescriptions(prescription_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_pi_medication FOREIGN KEY (medication_id)
    REFERENCES Medications(medication_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===================================================================
-- Payments (one-to-one with appointment)
-- ===================================================================

CREATE TABLE Payments (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT NOT NULL UNIQUE,
  amount DECIMAL(10,2) NOT NULL,
  paid_at TIMESTAMP NULL,
  method ENUM('Cash','Card','Online','Insurance') NOT NULL,
  status ENUM('Pending','Paid','Failed','Refunded') NOT NULL DEFAULT 'Pending',
  transaction_ref VARCHAR(200) UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_payment_appointment FOREIGN KEY (appointment_id)
    REFERENCES Appointments(appointment_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_payments_paid_at ON Payments(paid_at);

-- ===================================================================
-- Medical records / Encounter notes (one-to-one with appointment)
-- ===================================================================

CREATE TABLE Medical_Records (
  record_id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT NOT NULL UNIQUE,
  diagnosis TEXT,
  treatment TEXT,
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_record_appointment FOREIGN KEY (appointment_id)
    REFERENCES Appointments(appointment_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===================================================================
-- Audit logs
-- ===================================================================

CREATE TABLE Audit_Logs (
  log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NULL,
  action VARCHAR(255) NOT NULL,
  meta JSON,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_audit_user FOREIGN KEY (user_id)
    REFERENCES Users(user_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===================================================================
-- Triggers: prevent appointment overlaps for same doctor & same patient
-- (Basic check: no overlapping appointments in time range)
-- ===================================================================

DELIMITER $$

CREATE TRIGGER trg_appointments_no_overlap_before_insert
BEFORE INSERT ON Appointments
FOR EACH ROW
BEGIN
  DECLARE cnt INT DEFAULT 0;

  -- Check doctor overlapping appointments
  SELECT COUNT(*) INTO cnt
  FROM Appointments
  WHERE doctor_id = NEW.doctor_id
    AND NOT (scheduled_end <= NEW.scheduled_start OR scheduled_start >= NEW.scheduled_end);
  IF cnt > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doctor has overlapping appointment in the requested time range';
  END IF;

  -- Check patient overlapping appointments
  SELECT COUNT(*) INTO cnt
  FROM Appointments
  WHERE patient_id = NEW.patient_id
    AND NOT (scheduled_end <= NEW.scheduled_start OR scheduled_start >= NEW.scheduled_end);
  IF cnt > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient has overlapping appointment in the requested time range';
  END IF;
END$$

CREATE TRIGGER trg_appointments_no_overlap_before_update
BEFORE UPDATE ON Appointments
FOR EACH ROW
BEGIN
  DECLARE cnt INT DEFAULT 0;

  -- exclude the row being updated
  SELECT COUNT(*) INTO cnt
  FROM Appointments
  WHERE doctor_id = NEW.doctor_id
    AND appointment_id != OLD.appointment_id
    AND NOT (scheduled_end <= NEW.scheduled_start OR scheduled_start >= NEW.scheduled_end);
  IF cnt > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doctor has overlapping appointment in the requested time range';
  END IF;

  SELECT COUNT(*) INTO cnt
  FROM Appointments
  WHERE patient_id = NEW.patient_id
    AND appointment_id != OLD.appointment_id
    AND NOT (scheduled_end <= NEW.scheduled_start OR scheduled_start >= NEW.scheduled_end);
  IF cnt > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient has overlapping appointment in the requested time range';
  END IF;
END$$

DELIMITER ;

-- ===================================================================
-- Sample seed data (small) — optional, helpful for tests
-- ===================================================================

INSERT INTO Roles (role_name, description) VALUES
  ('Admin','System administrator'),
  ('Receptionist','Front desk user'),
  ('Doctor','Medical practitioner');

INSERT INTO Departments (name, description) VALUES
  ('General Medicine','General practice'), ('Pediatrics','Child health'), ('Surgery','Surgical dept');

INSERT INTO Specializations (name, description) VALUES
  ('General Practitioner','Primary care doctor'), ('Pediatrics','Children specialist'), ('Cardiology','Heart specialist');

INSERT INTO Users (username, password_hash, full_name, email, role_id) VALUES
  ('admin', 'change_me_hash', 'System Admin', 'admin@clinic.local', 1),
  ('reception', 'change_me_hash', 'Receptionist', 'reception@clinic.local', 2);

INSERT INTO Doctors (first_name, last_name, email, phone, license_no, department_id) VALUES
  ('Alice','Kebede','alice.k@clinic.local','+251911000001','LIC-0001', 1),
  ('Samuel','Bekele','samuel.b@clinic.local','+251911000002','LIC-0002', 2);

INSERT INTO Doctor_Specializations (doctor_id, specialization_id) VALUES
  (1, 1), (2, 2);

INSERT INTO Patients (first_name, last_name, date_of_birth, gender, phone, email) VALUES
  ('John','Doe','1990-01-01','Male','+251911111111','john.doe@example.com'),
  ('Sara','Mekonnen','1985-05-03','Female','+251911222222','sara.m@example.com');

INSERT INTO Rooms (room_number, room_type, floor) VALUES
  ('101','Consultation',1), ('201','Procedure',2);

-- Example appointment (valid)
INSERT INTO Appointments (patient_id, doctor_id, room_id, scheduled_start, scheduled_end, status, reason, created_by_user_id)
VALUES (1, 1, 1, '2025-10-01 09:00:00', '2025-10-01 09:30:00', 'Scheduled', 'Routine check', 2);

-- A sample medication and prescription
INSERT INTO Medications (name, generic_name, dosage_form, strength, manufacturer)
VALUES ('Amoxicillin 500mg Capsules', 'Amoxicillin', 'Capsule', '500 mg', 'ACME Pharma');

INSERT INTO Prescriptions (appointment_id, prescribed_by_doctor_id, notes)
VALUES (1, 1, 'Take after meals');

INSERT INTO Prescription_Items (prescription_id, medication_id, dosage, quantity, instructions)
VALUES (1, 1, '500 mg, 3 times daily', 21, 'Take with food');

-- Example payment (for appointment 1)
INSERT INTO Payments (appointment_id, amount, paid_at, method, status, transaction_ref)
VALUES (1, 25.00, '2025-10-01 10:00:00', 'Cash', 'Paid', 'TXN-00001');

-- ===================================================================


