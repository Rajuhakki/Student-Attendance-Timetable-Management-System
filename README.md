# 📘 Student Attendance & Timetable Management System

## 🚀 Project Overview

The **Student Attendance & Timetable Management System** is a cross-platform application developed to modernize the traditional method of managing attendance and academic schedules in educational institutions.

Manual attendance registers and paper-based timetables are time-consuming, difficult to maintain, and prone to errors or data loss. This system replaces those manual processes with a **digital, structured, and centralized solution** that improves efficiency, accuracy, and accessibility.

The application is designed for **faculty members and administrators**, enabling seamless attendance recording and timetable management across multiple departments and semesters.

📌 Core system reference:

---

## 🎯 Problem Statement

Traditional systems suffer from:

* Manual entry errors
* Time-consuming attendance tracking
* Lack of centralized data
* Difficulty in managing multiple classes and schedules
* No proper filtering or reporting system

This project solves these issues by providing a **simple, digital, and scalable system**.

---

## 🎯 Objectives

* Digitize attendance recording process
* Centralize timetable and schedule management
* Reduce human errors and data redundancy
* Provide easy access to attendance records
* Support multiple departments and semesters

---

## ⚙️ System Architecture

The system follows a **client-server architecture**:

### 1. Frontend (Flutter)

* User interface for faculty and admin
* Cross-platform (Android, Web, Desktop)

### 2. Backend (Node.js + Express)

* Handles API requests
* Manages communication with database

### 3. Database Layer

* **SQLite** → Local storage (offline support)
* **MongoDB** → Cloud storage (centralized access)

This hybrid approach ensures **performance + reliability**.

---

## ✨ Core Features

### 📊 Attendance Management

* Faculty can record attendance for each lecture
* Captures:

  * Classroom name
  * Student count
  * Faculty name
  * Date and time
* Stores data locally and syncs with backend
* Allows viewing past attendance records

---

### 📅 Timetable Management

* Admin can:

  * Create schedules
  * Update timetables
  * Delete entries
* Organized by:

  * Department
  * Semester (1–8)

---

### 🔐 Role-Based Access Control

* **Admin**

  * Full system control
  * Manage timetable and records

* **Faculty**

  * View schedules
  * Record attendance

---

### 🏫 Multi-Department Support

* Supports multiple departments such as:

  * CSE, ECE, ME, Civil, etc.
* Scalable for large institutions

---

### ☁️ Hybrid Data Storage

* **SQLite (Local):**

  * Enables offline functionality
  * Fast data access

* **MongoDB (Cloud):**

  * Centralized storage
  * Data backup and remote access

---

## 🔄 How It Works

1. Faculty opens the application
2. Selects **"Record Attendance"** option
3. Enters:

   * Classroom name
   * Number of students present
   * Faculty name
   * Date and time
4. Data is saved into **SQLite (local database)**
5. Admin accesses **"View Attendance Records"**
6. Records can be filtered by:

   * Classroom
   * Date

---

## 🛠️ Technology Stack

### Frontend

* Flutter (Dart)
* Provider (State Management)

### Backend

* Node.js
* Express.js

### Database

* MongoDB (Cloud)
* SQLite (Local)

---

## 📂 Project Structure

```
demo/
 ├── backend/            # Node.js API server
 ├── lib/                # Flutter source code
 ├── assets/             # Config files
 ├── screenshots/        # UI images
 ├── pubspec.yaml        # Dependencies
 └── README.md
```

---

## ⚙️ How to Run the Project

### 🔧 Backend Setup

```
cd backend
npm install
npm start
```

Server runs at:

```
http://localhost:3002
```

---

### 📱 Flutter App

```
cd demo
flutter pub get
flutter run
```

---

## 🌐 API Endpoints

### Schedule APIs

* `GET /api/schedules/semester/:semester`
* `POST /api/schedules`
* `PUT /api/schedules/:id`
* `DELETE /api/schedules/:id`

---

## 🎯 Applications

* Colleges and universities
* Faculty attendance tracking
* Timetable management systems

---

## 📈 Advantages

* Eliminates manual work
* Improves accuracy
* Easy to use interface
* Works offline and online
* Scalable system

---

## 🔮 Future Enhancements

* Dashboard analytics
* Notification system
* UI/UX improvements
* Student login integration

---

## 🤝 Contributing

1. Fork the repository
2. Create a new branch:

   ```
   git checkout -b feature/AmazingFeature
   ```
3. Commit your changes:

   ```
   git commit -m "Add some AmazingFeature"
   ```
4. Push to GitHub:

   ```
   git push origin feature/AmazingFeature
   ```
5. Open a Pull Request

---

## 📜 License

This project is licensed under the **MIT License**:
https://github.com/Rajuhakki/Student-Attendance-Timetable-Management-System/blob/main/LICENSE

---

## 📞 Contact

## Email:  [rajuhakki21@gmail.com](mailto:rajuhakki21@gmail.com).

---

## 👨‍💻 Author

**Raju Hakki**

---

## ⭐ Conclusion

The **Student Attendance & Timetable Management System** provides a reliable, efficient, and scalable solution for managing academic attendance and schedules. By replacing manual processes with a digital system, it significantly improves productivity and data accuracy in educational institutions.
