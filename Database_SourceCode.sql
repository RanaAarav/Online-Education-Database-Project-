-- Creating Tables
CREATE TABLE Users (
UserID NUMBER GENERATED ALWAYS AS IDENTITY,
FirstName VARCHAR2(50) NOT NULL,
LastName VARCHAR2(50) NOT NULL,
Email VARCHAR2(100) UNIQUE NOT NULL,
Password VARCHAR2(100) NOT NULL,
Role VARCHAR2(20) NOT NULL,
CreatedAt DATE DEFAULT SYSDATE,
UpdatedAt DATE DEFAULT SYSDATE,
CONSTRAINT PK_Users PRIMARY KEY (UserID),
CONSTRAINT CHK_Role CHECK (Role IN ('Student', 'Instructor', 'Administrator'))
);

CREATE TABLE Courses (
CourseID NUMBER GENERATED ALWAYS AS IDENTITY,
Title VARCHAR2(200) NOT NULL,
Description VARCHAR2(4000),
InstructorID NUMBER NOT NULL,
Duration NUMBER,
EnrollmentStartDate DATE NOT NULL,
EnrollmentEndDate DATE NOT NULL,
IsEnrollmentOpen NUMBER(1) DEFAULT 1,
CONSTRAINT PK_Courses PRIMARY KEY (CourseID),
CONSTRAINT FK_Courses_Instructor FOREIGN KEY (InstructorID) REFERENCES Users(UserID)
);

CREATE TABLE Modules (
ModuleID NUMBER GENERATED ALWAYS AS IDENTITY,
CourseID NUMBER NOT NULL,
Title VARCHAR2(200) NOT NULL,
Description VARCHAR2(4000),
OrderNumber NUMBER NOT NULL,
CONSTRAINT PK_Modules PRIMARY KEY (ModuleID),
CONSTRAINT FK_Modules_Course FOREIGN KEY (CourseID) REFERENCES Courses(CourseID)
);

CREATE TABLE Lessons (
LessonID NUMBER GENERATED ALWAYS AS IDENTITY,
ModuleID NUMBER NOT NULL,
Title VARCHAR2(200) NOT NULL,
Description VARCHAR2(4000),
OrderNumber NUMBER NOT NULL,
CONSTRAINT PK_Lessons PRIMARY KEY (LessonID),
CONSTRAINT FK_Lessons_Module FOREIGN KEY (ModuleID) REFERENCES Modules(ModuleID)
);

CREATE TABLE Content (
ContentID NUMBER GENERATED ALWAYS AS IDENTITY,
LessonID NUMBER NOT NULL,
Type VARCHAR2(20) NOT NULL,
Title VARCHAR2(200) NOT NULL,
Description VARCHAR2(4000),
FilePath VARCHAR2(500),
Version NUMBER DEFAULT 1,
CONSTRAINT PK_Content PRIMARY KEY (ContentID),
CONSTRAINT FK_Content_Lesson FOREIGN KEY (LessonID) REFERENCES Lessons(LessonID)
);

CREATE TABLE UserEnrollments (
EnrollmentID NUMBER GENERATED ALWAYS AS IDENTITY,
UserID NUMBER NOT NULL,
CourseID NUMBER NOT NULL,
EnrollmentDate DATE DEFAULT SYSDATE,
CompletionStatus VARCHAR2(20) DEFAULT 'Enrolled',
CONSTRAINT PK_UserEnrollments PRIMARY KEY (EnrollmentID),
CONSTRAINT FK_UserEnrollments_User FOREIGN KEY (UserID) REFERENCES Users(UserID),
CONSTRAINT FK_UserEnrollments_Course FOREIGN KEY (CourseID) REFERENCES Courses(CourseID)
);

CREATE TABLE Assessments (
AssessmentID NUMBER GENERATED ALWAYS AS IDENTITY,
LessonID NUMBER NOT NULL,
Type VARCHAR2(20) NOT NULL,
Title VARCHAR2(200) NOT NULL,
Description VARCHAR2(4000),
DueDate DATE NOT NULL,
CONSTRAINT PK_Assessments PRIMARY KEY (AssessmentID),
CONSTRAINT FK_Assessments_Lesson FOREIGN KEY (LessonID) REFERENCES Lessons(LessonID)
);

CREATE TABLE UserAssessmentAttempts (
AttemptID NUMBER GENERATED ALWAYS AS IDENTITY,
UserID NUMBER NOT NULL,
AssessmentID NUMBER NOT NULL,
AttemptDate DATE DEFAULT SYSDATE,
Score NUMBER,
CONSTRAINT PK_UserAssessmentAttempts PRIMARY KEY (AttemptID),
CONSTRAINT FK_UserAssessmentAttempts_User FOREIGN KEY (UserID) REFERENCES Users(UserID),
CONSTRAINT FK_UserAssessmentAttempts_Assessment FOREIGN KEY (AssessmentID) REFERENCES Assessments(AssessmentID)
);

CREATE TABLE UserInteractions (
InteractionID NUMBER GENERATED ALWAYS AS IDENTITY,
UserID NUMBER NOT NULL,
ContentID NUMBER NOT NULL,
InteractionType VARCHAR2(20) NOT NULL,
InteractionTimestamp DATE DEFAULT SYSDATE,
CONSTRAINT PK_UserInteractions PRIMARY KEY (InteractionID),
CONSTRAINT FK_UserInteractions_User FOREIGN KEY (UserID) REFERENCES Users(UserID),
CONSTRAINT FK_UserInteractions_Content FOREIGN KEY (ContentID) REFERENCES Content(ContentID)
);

CREATE TABLE Forums (
ForumID NUMBER GENERATED ALWAYS AS IDENTITY,
CourseID NUMBER NOT NULL,
Title VARCHAR2(200) NOT NULL,
Description VARCHAR2(4000),
CONSTRAINT PK_Forums PRIMARY KEY (ForumID),
CONSTRAINT FK_Forums_Course FOREIGN KEY (CourseID) REFERENCES Courses(CourseID)
);

CREATE TABLE ForumThreads (
ThreadID NUMBER GENERATED ALWAYS AS IDENTITY,
ForumID NUMBER NOT NULL,
UserID NUMBER NOT NULL,
Title VARCHAR2(200) NOT NULL,
CreatedAt DATE DEFAULT SYSDATE,
CONSTRAINT PK_ForumThreads PRIMARY KEY (ThreadID),
CONSTRAINT FK_ForumThreads_Forum FOREIGN KEY (ForumID) REFERENCES Forums(ForumID),
CONSTRAINT FK_ForumThreads_User FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

CREATE TABLE ForumPosts (
PostID NUMBER GENERATED ALWAYS AS IDENTITY,
ThreadID NUMBER NOT NULL,
UserID NUMBER NOT NULL,
Content VARCHAR2(4000) NOT NULL,
CreatedAt DATE DEFAULT SYSDATE,
CONSTRAINT PK_ForumPosts PRIMARY KEY (PostID),
CONSTRAINT FK_ForumPosts_Thread FOREIGN KEY (ThreadID) REFERENCES ForumThreads(ThreadID),
CONSTRAINT FK_ForumPosts_User FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

CREATE TABLE Payments (
PaymentID NUMBER GENERATED ALWAYS AS IDENTITY,
UserID NUMBER NOT NULL,
CourseID NUMBER NOT NULL,
PaymentAmount NUMBER NOT NULL,
PaymentDate DATE DEFAULT SYSDATE,
PaymentStatus VARCHAR2(20) DEFAULT 'Pending',
CONSTRAINT PK_Payments PRIMARY KEY (PaymentID),
CONSTRAINT FK_Payments_User FOREIGN KEY (UserID) REFERENCES Users(UserID),
CONSTRAINT FK_Payments_Course FOREIGN KEY (CourseID) REFERENCES Courses(CourseID)
);

CREATE TABLE Discounts (
DiscountID NUMBER GENERATED ALWAYS AS IDENTITY,
DiscountCode VARCHAR2(20) UNIQUE NOT NULL,
DiscountPercentage NUMBER NOT NULL,
StartDate DATE NOT NULL,
EndDate DATE NOT NULL,
CONSTRAINT PK_Discounts PRIMARY KEY (DiscountID)
);

CREATE TABLE UserDiscounts (
UserDiscountID NUMBER GENERATED ALWAYS AS IDENTITY,
UserID NUMBER NOT NULL,
DiscountID NUMBER NOT NULL,
AppliedDate DATE DEFAULT SYSDATE,
CONSTRAINT PK_UserDiscounts PRIMARY KEY (UserDiscountID),
CONSTRAINT FK_UserDiscounts_User FOREIGN KEY (UserID) REFERENCES Users(UserID),
CONSTRAINT FK_UserDiscounts_Discount FOREIGN KEY (DiscountID) REFERENCES Discounts(DiscountID)
);

-- PL/SQL Components

-- 1. Procedure: CreateUser
CREATE OR REPLACE PROCEDURE CreateUser(
    p_FirstName IN VARCHAR2,
    p_LastName IN VARCHAR2,
    p_Email IN VARCHAR2,
    p_Password IN VARCHAR2,
    p_Role IN VARCHAR2
)
IS
    l_PasswordHash RAW(100);  -- Use RAW data type for storing hash values
    l_Count NUMBER := 0;
BEGIN
    -- Validate input parameters
    IF p_FirstName IS NULL OR p_LastName IS NULL OR p_Email IS NULL OR p_Password IS NULL OR p_Role NOT IN ('Student', 'Instructor', 'Administrator') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid input parameters');
    END IF;

    -- Check if the email already exists
    SELECT COUNT(*) INTO l_Count
    FROM Users
    WHERE Email = p_Email;

    IF l_Count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Email already exists');
    END IF;

    -- Hash the password using DBMS_CRYPTO
    l_PasswordHash := DBMS_CRYPTO.HASH(Utl_Raw.Cast_To_Raw(p_Password), DBMS_CRYPTO.HASH_MD5);

    -- Insert new user
    INSERT INTO Users (FirstName, LastName, Email, Password, Role)
    VALUES (p_FirstName, p_LastName, p_Email, l_PasswordHash, p_Role);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END CreateUser;
/


-- 2. Procedure: EnrollUserInCourse
CREATE OR REPLACE PROCEDURE EnrollUserInCourse(
p_UserID IN NUMBER,
p_CourseID IN NUMBER,
p_EnrollmentDate IN DATE
)
IS
l_EnrollmentStartDate DATE;
l_EnrollmentEndDate DATE;
l_IsEnrolled NUMBER;
BEGIN
-- Validate input parameters
IF p_UserID IS NULL OR p_CourseID IS NULL OR p_EnrollmentDate IS NULL THEN
RAISE_APPLICATION_ERROR(-20003, 'Invalid input parameters');
END IF;

-- Check if the user is already enrolled in the course
SELECT COUNT(*) INTO l_IsEnrolled
FROM UserEnrollments
WHERE UserID = p_UserID AND CourseID = p_CourseID;

IF l_IsEnrolled > 0 THEN
    RAISE_APPLICATION_ERROR(-20004, 'User is already enrolled in the course');
END IF;

-- Verify if the course enrollment is open
SELECT EnrollmentStartDate, EnrollmentEndDate INTO l_EnrollmentStartDate, l_EnrollmentEndDate
FROM Courses
WHERE CourseID = p_CourseID;

IF p_EnrollmentDate < l_EnrollmentStartDate OR p_EnrollmentDate > l_EnrollmentEndDate THEN
    RAISE_APPLICATION_ERROR(-20005, 'Enrollment is not open for the specified course');
END IF;

-- Insert new enrollment record
INSERT INTO UserEnrollments (UserID, CourseID, EnrollmentDate)
VALUES (p_UserID, p_CourseID, p_EnrollmentDate);

COMMIT;

EXCEPTION
WHEN OTHERS THEN
ROLLBACK;
RAISE;
END;
/

-- 3. Procedure: SubmitAssessment
CREATE OR REPLACE PROCEDURE SubmitAssessment(
p_UserID IN NUMBER,
p_AssessmentID IN NUMBER,
p_AttemptDate IN DATE,
p_Score IN NUMBER
)
IS
l_CourseID NUMBER;
l_DueDate DATE;
l_IsEnrolled NUMBER;
BEGIN
-- Validate input parameters
IF p_UserID IS NULL OR p_AssessmentID IS NULL OR p_AttemptDate IS NULL OR p_Score IS NULL THEN
RAISE_APPLICATION_ERROR(-20006, 'Invalid input parameters');
END IF;

-- Check if the user is enrolled in the course associated with the assessment
SELECT c.CourseID INTO l_CourseID
FROM Assessments a
JOIN Lessons l ON a.LessonID = l.LessonID
JOIN Modules m ON l.ModuleID = m.ModuleID
JOIN Courses c ON m.CourseID = c.CourseID
WHERE a.AssessmentID = p_AssessmentID;

SELECT COUNT(*) INTO l_IsEnrolled
FROM UserEnrollments
WHERE UserID = p_UserID AND CourseID = l_CourseID;

IF l_IsEnrolled = 0 THEN
    RAISE_APPLICATION_ERROR(-20007, 'User is not enrolled in the course associated with the assessment');
END IF;

-- Verify if the assessment due date has not passed
SELECT DueDate INTO l_DueDate
FROM Assessments
WHERE AssessmentID = p_AssessmentID;

IF p_AttemptDate > l_DueDate THEN
    RAISE_APPLICATION_ERROR(-20008, 'Assessment due date has passed');
END IF;

-- Insert user assessment attempt
INSERT INTO UserAssessmentAttempts (UserID, AssessmentID, AttemptDate, Score)
VALUES (p_UserID, p_AssessmentID, p_AttemptDate, p_Score);

-- Update user progress or completion status in the course

COMMIT;

EXCEPTION
WHEN OTHERS THEN
ROLLBACK;
RAISE;
END;
/

CREATE OR REPLACE FUNCTION CALCULATEDISCOUNTEDPRICE(
    p_CourseID IN NUMBER,
    p_UserID IN NUMBER
) RETURN NUMBER
IS
    l_DiscountFactor NUMBER := 0.9;  -- Example discount factor (10% off)
    l_BasePrice NUMBER;
    l_DiscountedPrice NUMBER;
BEGIN
    -- Retrieve base price of the course
    SELECT DURATION * 10 INTO l_BasePrice
    FROM COURSES
    WHERE COURSEID = p_CourseID;

    -- Calculate discounted price
    l_DiscountedPrice := l_BasePrice * l_DiscountFactor;

    RETURN l_DiscountedPrice;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;  -- Return 0 or handle appropriately for no data found
END CALCULATEDISCOUNTEDPRICE;
/

    
CREATE OR REPLACE PROCEDURE ProcessPayment(
    p_UserID IN NUMBER,
    p_CourseID IN NUMBER,
    p_PaymentAmount IN NUMBER,
    p_PaymentMethod IN VARCHAR2
)
IS
    l_IsEnrolled NUMBER;
    l_DiscountedPrice NUMBER;
BEGIN
    -- Validate input parameters
    IF p_UserID IS NULL OR p_CourseID IS NULL OR p_PaymentAmount IS NULL OR p_PaymentMethod IS NULL THEN
        RAISE_APPLICATION_ERROR(-20009, 'Invalid input parameters');
    END IF;

    -- Check if the user is already enrolled in the course
    SELECT COUNT(*) INTO l_IsEnrolled
    FROM UserEnrollments
    WHERE UserID = p_UserID AND CourseID = p_CourseID;

    IF l_IsEnrolled > 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'User is already enrolled in the course');
    END IF;

    -- Calculate discounted price
    l_DiscountedPrice := CALCULATEDISCOUNTEDPRICE(p_CourseID, p_UserID);

    -- Process payment based on the payment method
    IF p_PaymentMethod = 'Credit Card' THEN
        -- Process credit card payment logic
        -- Example: Call a credit card processing API or execute SQL statements for credit card payment
        NULL; -- Placeholder for credit card processing logic
    ELSIF p_PaymentMethod = 'PayPal' THEN
        -- Process PayPal payment logic
        -- Example: Integrate with PayPal API or execute PayPal-specific logic
        NULL; -- Placeholder for PayPal processing logic
    ELSE
        RAISE_APPLICATION_ERROR(-20011, 'Invalid payment method');
    END IF;

    -- Insert payment record
    INSERT INTO Payments (UserID, CourseID, PaymentAmount)
    VALUES (p_UserID, p_CourseID, l_DiscountedPrice);

    -- Update user enrollment status to 'Paid'
    UPDATE UserEnrollments
    SET CompletionStatus = 'Paid'
    WHERE UserID = p_UserID AND CourseID = p_CourseID;

    COMMIT; -- Commit transaction if everything succeeds
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; -- Rollback transaction on error
        RAISE;    -- Propagate the exception
END ProcessPayment;
/

-- Triggers

-- 1. Trigger: ContentVersionTrigger
CREATE OR REPLACE TRIGGER ContentVersionTrigger
BEFORE UPDATE ON Content
FOR EACH ROW
BEGIN
:NEW.Version := :OLD.Version + 1;
END;
/

-- 2. Trigger: EnrollmentClosureTrigger
CREATE OR REPLACE TRIGGER EnrollmentClosureTrigger
BEFORE INSERT ON UserEnrollments
FOR EACH ROW
DECLARE
l_EnrollmentStartDate DATE;
l_EnrollmentEndDate DATE;
BEGIN
SELECT EnrollmentStartDate, EnrollmentEndDate INTO l_EnrollmentStartDate, l_EnrollmentEndDate
FROM Courses
WHERE CourseID = :NEW.CourseID;

IF :NEW.EnrollmentDate < l_EnrollmentStartDate OR :NEW.EnrollmentDate > l_EnrollmentEndDate THEN
    RAISE_APPLICATION_ERROR(-20012, 'Enrollment is not open for the specified course');
END IF;

END;
/

/* Don't Use not working
CREATE OR REPLACE TRIGGER ForumThreadCreationTrigger
AFTER INSERT ON ForumPosts
FOR EACH ROW
DECLARE
    l_ThreadCount NUMBER;
    v_ForumID NUMBER;
    v_CourseID NUMBER;
BEGIN
    -- Retrieve CourseID associated with the inserted PostID
    SELECT fp.CourseID
    INTO v_CourseID
    FROM ForumPosts fp
    WHERE fp.PostID = :NEW.PostID;

    -- Retrieve ForumID associated with the CourseID
    SELECT f.ForumID
    INTO v_ForumID
    FROM Forums f
    WHERE f.CourseID = v_CourseID;

    -- Count existing threads in the Forum
    SELECT COUNT(*)
    INTO l_ThreadCount
    FROM ForumThreads ft
    WHERE ft.ForumID = v_ForumID;

    -- If no threads exist, create a new thread
    IF l_ThreadCount = 0 THEN
        INSERT INTO ForumThreads (ForumID, UserID, Title)
        VALUES (v_ForumID, :NEW.UserID, :NEW.Content);  -- Assuming :NEW.Content is the thread title

        -- Retrieve the newly inserted ThreadID
        SELECT ThreadID
        INTO :NEW.ThreadID
        FROM ForumThreads
        WHERE ForumID = v_ForumID
          AND UserID = :NEW.UserID
          AND Title = :NEW.Content;  -- Assuming Title is matched by :NEW.Content
    END IF;
END;
/
*/



-- Cursors

-- 1. Cursor: CourseEnrollmentCursor
CREATE OR REPLACE FUNCTION CourseEnrollmentCursor(p_CourseID IN NUMBER)
RETURN SYS_REFCURSOR
IS
l_Cursor SYS_REFCURSOR;
BEGIN
OPEN l_Cursor FOR
SELECT u.FirstName, u.LastName, ue.EnrollmentDate
FROM Users u
JOIN UserEnrollments ue ON u.UserID = ue.UserID
WHERE ue.CourseID = p_CourseID
ORDER BY ue.EnrollmentDate ASC;

RETURN l_Cursor;

END;
/

-- 2. Cursor: TopPerformersCursor
CREATE OR REPLACE FUNCTION TopPerformersCursor(p_CourseID IN NUMBER, p_TopCount IN NUMBER)
RETURN SYS_REFCURSOR
IS
l_Cursor SYS_REFCURSOR;
BEGIN
OPEN l_Cursor FOR
SELECT u.FirstName, u.LastName, SUM(ua.Score) AS TotalScore
FROM Users u
JOIN UserAssessmentAttempts ua ON u.UserID = ua.UserID
JOIN Assessments a ON ua.AssessmentID = a.AssessmentID
JOIN Lessons l ON a.LessonID = l.LessonID
JOIN Modules m ON l.ModuleID = m.ModuleID
JOIN Courses c ON m.CourseID = c.CourseID
WHERE c.CourseID = p_CourseID
GROUP BY u.FirstName, u.LastName
ORDER BY TotalScore DESC
FETCH FIRST p_TopCount ROWS ONLY;

RETURN l_Cursor;

END;
/

-- 3. Cursor: PendingAssessmentsCursor
CREATE OR REPLACE FUNCTION PendingAssessmentsCursor(p_UserID IN NUMBER)
RETURN SYS_REFCURSOR
IS
l_Cursor SYS_REFCURSOR;
BEGIN
OPEN l_Cursor FOR
SELECT a.Title, a.DueDate
FROM Assessments a
JOIN Lessons l ON a.LessonID = l.LessonID
JOIN Modules m ON l.ModuleID = m.ModuleID
JOIN Courses c ON m.CourseID = c.CourseID
JOIN UserEnrollments ue ON c.CourseID = ue.CourseID AND ue.UserID = p_UserID
WHERE ue.CompletionStatus = 'Enrolled'
AND a.DueDate > SYSDATE;

RETURN l_Cursor;

END;
/

-- 4. Cursor: RecentActivityCursor
CREATE OR REPLACE FUNCTION RecentActivityCursor(p_UserID IN NUMBER, p_ActivityDays IN NUMBER)
RETURN SYS_REFCURSOR
IS
l_Cursor SYS_REFCURSOR;
BEGIN
OPEN l_Cursor FOR
SELECT c.Title, ui.InteractionType, ui.InteractionTimestamp
FROM UserInteractions ui
JOIN Content c ON ui.ContentID = c.ContentID
WHERE ui.UserID = p_UserID
AND ui.InteractionTimestamp > SYSDATE - p_ActivityDays
ORDER BY ui.InteractionTimestamp DESC;

RETURN l_Cursor;

END;
/

-- Error Handling

-- 1. Exception: DuplicateEmailException
CREATE OR REPLACE PROCEDURE HandleDuplicateEmailException
IS
BEGIN
RAISE_APPLICATION_ERROR(-20002, 'Email already exists');
EXCEPTION
WHEN OTHERS THEN
RAISE;
END;
/

-- 2. Exception: EnrollmentClosedException
CREATE OR REPLACE PROCEDURE HandleEnrollmentClosedException
IS
BEGIN
RAISE_APPLICATION_ERROR(-20005, 'Enrollment is not open for the specified course');
EXCEPTION
WHEN OTHERS THEN
RAISE;
END;
/

-- 3. Exception: AssessmentDueDateViolationException
CREATE OR REPLACE PROCEDURE HandleAssessmentDueDateViolationException
IS
BEGIN
RAISE_APPLICATION_ERROR(-20013, 'Assessment due date cannot be in the past');
EXCEPTION
WHEN OTHERS THEN
RAISE;
END;
/

-- 4. Exception: PaymentFailureException
CREATE OR REPLACE PROCEDURE HandlePaymentFailureException
IS
BEGIN
RAISE_APPLICATION_ERROR(-20014, 'Payment processing failed');
EXCEPTION
WHEN OTHERS THEN
RAISE;
END;
/

-- Stored Functions

-- 1. Function: CalculateDiscountedPrice
CREATE OR REPLACE FUNCTION CalculateDiscountedPrice(
p_CourseID IN NUMBER,
p_UserID IN NUMBER
)
RETURN NUMBER
IS
l_RegularPrice NUMBER;
l_DiscountedPrice NUMBER;
l_DiscountPercentage NUMBER;
BEGIN
-- Retrieve the regular price of the course
SELECT c.Duration INTO l_RegularPrice
FROM Courses c
WHERE c.CourseID = p_CourseID;

-- Check if the user has any applicable discounts
SELECT d.DiscountPercentage INTO l_DiscountPercentage
FROM UserDiscounts ud
JOIN Discounts d ON ud.DiscountID = d.DiscountID
WHERE ud.UserID = p_UserID
  AND d.StartDate <= SYSDATE
  AND d.EndDate >= SYSDATE
  AND ROWNUM = 1;

-- Calculate the discounted price
l_DiscountedPrice := l_RegularPrice - (l_RegularPrice * l_DiscountPercentage / 100);

RETURN l_DiscountedPrice;

EXCEPTION
WHEN NO_DATA_FOUND THEN
RETURN l_RegularPrice;
WHEN OTHERS THEN
RAISE;
END;
/

-- 2. Function: GetUserRoleDescription
CREATE OR REPLACE FUNCTION GetUserRoleDescription(
p_RoleID IN VARCHAR2
)
RETURN VARCHAR2
IS
l_RoleDescription VARCHAR2(20);
BEGIN
CASE p_RoleID
WHEN 'Student' THEN
l_RoleDescription := 'Student';
WHEN 'Instructor' THEN
l_RoleDescription := 'Instructor';
WHEN 'Administrator' THEN
l_RoleDescription := 'Administrator';
ELSE
l_RoleDescription := 'Unknown';
END CASE;
RETURN l_RoleDescription;
END;
/

-- 3. Function: CalculateCourseProgress
CREATE OR REPLACE FUNCTION CalculateCourseProgress(
    p_UserID IN NUMBER,
    p_CourseID IN NUMBER
)
RETURN NUMBER
IS
    l_TotalLessons NUMBER;
    l_CompletedLessons NUMBER;
    l_TotalAssessments NUMBER;
    l_CompletedAssessments NUMBER;
    l_Progress NUMBER;
BEGIN
    -- Calculate total lessons and assessments in the course
    SELECT COUNT(DISTINCT l.LessonID), COUNT(DISTINCT a.AssessmentID)
    INTO l_TotalLessons, l_TotalAssessments
    FROM Lessons l
    JOIN Modules m ON l.ModuleID = m.ModuleID
    JOIN Courses c ON m.CourseID = c.CourseID
    LEFT JOIN Assessments a ON l.LessonID = a.LessonID
    WHERE c.CourseID = p_CourseID;

    -- Calculate completed lessons and assessments for the user
    SELECT COUNT(DISTINCT ui.ContentID), COUNT(DISTINCT ua.AssessmentID)
    INTO l_CompletedLessons, l_CompletedAssessments
    FROM UserInteractions ui
    JOIN Content c ON ui.ContentID = c.ContentID
    JOIN Lessons l ON c.LessonID = l.LessonID
    LEFT JOIN UserAssessmentAttempts ua ON ui.UserID = ua.UserID AND l.LessonID = (
        SELECT l2.LessonID
        FROM Lessons l2
        JOIN Assessments a ON l2.LessonID = a.LessonID
        WHERE a.AssessmentID = ua.AssessmentID
    )
    WHERE ui.UserID = p_UserID
      AND ui.InteractionType = 'Completed'
      AND l.LessonID IN (
        SELECT l3.LessonID
        FROM Lessons l3
        JOIN Modules m ON l3.ModuleID = m.ModuleID
        JOIN Courses c ON m.CourseID = c.CourseID
        WHERE c.CourseID = p_CourseID
    );

    -- Calculate overall progress
    l_Progress := ROUND((
        (l_CompletedLessons / NULLIF(l_TotalLessons, 0)) * 0.6 +
        (l_CompletedAssessments / NULLIF(l_TotalAssessments, 0)) * 0.4
    ) * 100, 2);

    RETURN l_Progress;
END;
/

-- Insert some sample users
INSERT INTO Users (FirstName, LastName, Email, Password, Role) 
VALUES ('John', 'Doe', 'john.doe@example.com', 'password123', 'Student');

INSERT INTO Users (FirstName, LastName, Email, Password, Role) 
VALUES ('Jane', 'Smith', 'jane.smith@example.com', 'password456', 'Instructor');

-- Insert a sample course
INSERT INTO Courses (Title, Description, InstructorID, EnrollmentStartDate, EnrollmentEndDate) 
VALUES ('Introduction to SQL', 'A beginner’s guide to SQL and databases.', 2, TO_DATE('2024-01-01', 'YYYY-MM-DD'), TO_DATE('2024-06-30', 'YYYY-MM-DD'));
