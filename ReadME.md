# Online Education Database System Project

This project is an **Online Education Database System** built using **Oracle Database** and **PL/SQL**. It provides the backend database structure for an online education platform, managing users, courses, assessments, content, forums, payments, and more.

The system is designed to support various educational processes, including user enrollment, course management, content distribution, and payment processing. It uses a relational database model with multiple interrelated tables and foreign key constraints to ensure referential integrity.

## Features
- **User Management**: Roles for students, instructors, and administrators.
- **Course Management**: Includes course details, enrollment periods, and course instructors.
- **Content Management**: Manage course materials, including files and media associated with lessons.
- **Assessments**: Track quizzes, exams, and other assessments for users.
- **Enrollment & Payments**: Users can enroll in courses, make payments, and apply discount codes.
- **Forums**: Discussion threads for courses to encourage user interaction.
- **PL/SQL Components**: Automate processes like enrollment, payments, and content management.

## Database & Technology

- **Database**: Oracle Database (SQL and PL/SQL)
- **PL/SQL**: Used for creating stored procedures, functions, and triggers for automating common operations such as user enrollment, content creation, and payment processing.
  
The database schema is designed with the following key tables:
- **Users**: Stores user details (students, instructors, admins).
- **Courses**: Contains information on available courses.
- **Modules and Lessons**: Hierarchical structure for course content.
- **Assessments**: Tracks assessments like quizzes and tests.
- **Payments and Discounts**: Manages user payments and discount applications.

## Project Setup

1. **Clone the Repository**

2. **Set Up the Oracle Database**
   Set up an Oracle Database instance.
   Import the provided SQL schema files to create the necessary tables and relationships.
   The database schema includes CREATE TABLE scripts, along with PL/SQL procedures to automate tasks such as enrolling users and processing payments.
3. **Use PL/SQL for Automation**:
   Stored procedures are provided to automate operations like enrolling users in courses, adding content to lessons, and processing payments.
