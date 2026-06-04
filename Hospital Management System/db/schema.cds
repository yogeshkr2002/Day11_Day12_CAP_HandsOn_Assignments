namespace edu.university;


type Email      : String(100);
type Phone      : String(15);
type Percentage : Decimal(5,2);
type GradePoint : Decimal(3,2);
type Semester   : Integer;


type Designation : String enum {
    Assistant;
    Associate;
    Full;
    Distinguished;
};

type EnrollmentStatus : String enum {
    Enrolled;
    Dropped;
    Completed;
};

type Grade : String enum {
    A;
    B;
    C;
    D;
    F;
};

type ExamType : String enum {
    Midterm;
    Final;
    Quiz;
    Assignment;
};



entity Departments {

    key code            : String(10);

    name                : String(100);
    building            : String(100);
    headProfessor       : String(100);
    establishedYear     : Integer;
}

entity Professors {

    key ID              : UUID;

    firstName           : String(50);
    lastName            : String(50);

    email               : Email;
    phone               : Phone;

    department          : Association to Departments;

    designation         : Designation;

    joinDate            : Date;

    salary              : Decimal(12,2);

    officeRoom          : String(20);
}

entity Courses {

    key code            : String(10);

    title               : String(100);
    description         : String(500);

    credits             : Integer;

    maxStudents         : Integer;

    currentEnrolled     : Integer default 0;

    semester            : Semester;

    department          : Association to Departments;

    professor           : Association to Professors;

    schedule            : String(100);

    roomNumber          : String(20);

    isActive            : Boolean default true;
}

entity Students {

    key ID              : UUID;

    rollNumber          : String(20);

    firstName           : String(50);
    lastName            : String(50);

    email               : Email;
    phone               : Phone;

    dateOfBirth         : Date;

    admissionYear       : Integer;

    currentSemester     : Semester;

    cgpa                : Decimal(3,2);

    department          : Association to Departments;

    isActive            : Boolean default true;
}

entity Enrollments {

    key student         : Association to Students;
    key course          : Association to Courses;

    enrollmentDate      : Date;

    status              : EnrollmentStatus default 'Enrolled';

    grade               : Grade;

    gradePoints         : GradePoint;

    attendancePercent   : Percentage;
}

entity Exams {

    key ID              : UUID;

    course              : Association to Courses;

    examType            : ExamType;

    date                : Date;

    maxMarks            : Integer;

    weightagePercent    : Percentage;
}