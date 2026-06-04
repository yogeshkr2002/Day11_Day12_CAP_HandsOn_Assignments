using edu.university as db from '../db/schema';

service UniversityService {

    entity Departments as projection on db.Departments;

    entity Professors as projection on db.Professors;

    entity Courses as projection on db.Courses;

    entity Students as projection on db.Students;

    entity Enrollments as projection on db.Enrollments;

    entity Exams as projection on db.Exams;

}