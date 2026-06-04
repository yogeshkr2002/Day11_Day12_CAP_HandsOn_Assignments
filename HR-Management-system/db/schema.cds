namespace com.hr;

using { cuid, managed, Currency, Country } from '@sap/cds/common';

type ProjectStatus : String(20) enum {
  Planning   = 'Planning';
  Active     = 'Active';
  OnHold     = 'On Hold';
  Completed  = 'Completed';
  Cancelled  = 'Cancelled';
}

type Proficiency : String(20) enum {
  Beginner     = 'Beginner';
  Intermediate = 'Intermediate';
  Advanced     = 'Advanced';
  Expert       = 'Expert';
}

type SkillCategory : String(30) enum {
  Technical    = 'Technical';
  Soft         = 'Soft';
  Management   = 'Management';
  Domain       = 'Domain';
}

entity Departments : cuid, managed {
  deptName      : String(100);
  description   : String(500);
  budget        : Decimal(12,2);
  currency      : Currency;
  location      : String(100);
  head          : Association to Employees;
  employees     : Association to many Employees on employees.department = $self;
}

entity Employees : cuid, managed {
  firstName     : String(50);
  lastName      : String(50);
  email         : String(255);
  phone         : String(20);
  hireDate      : Date;
  salary        : Decimal(10,2);
  currency      : Currency;
  jobTitle      : String(100);
  isActive      : Boolean default true;
  country       : Country;
  department    : Association to Departments;
  assignments   : Association to many Assignments on assignments.employee = $self;
  skills        : Association to many EmployeeSkills on skills.employee = $self;
}

entity Projects : cuid, managed {
  projectName   : String(150);
  description   : String(1000);
  startDate     : Date;
  endDate       : Date;
  budget        : Decimal(12,2);
  currency      : Currency;
  status        : ProjectStatus default 'Planning';
  manager       : Association to Employees;
  assignments   : Association to many Assignments on assignments.project = $self;
}

entity Skills : cuid, managed {
  skillName     : String(100);
  category      : SkillCategory;
  description   : String(500);
  employeeSkills : Association to many EmployeeSkills on employeeSkills.skill = $self;
}

entity Assignments : cuid, managed {
  employee      : Association to Employees;
  project       : Association to Projects;
  role          : String(100);
  allocation    : Integer;  
  startDate     : Date;
  endDate       : Date;
}

entity EmployeeSkills : cuid, managed {
  employee        : Association to Employees;
  skill           : Association to Skills;
  proficiency     : Proficiency default 'Beginner';
  yearsOfExperience : Decimal(3,1);
  certifiedDate   : Date;
}

entity TeamOverview as select from Employees {
  ID,
  firstName,
  lastName,
  email,
  jobTitle,
  salary,
  hireDate,
  isActive,
  department.deptName as departmentName
} where isActive = true;

entity ProjectDashboard as select from Projects {
  ID,
  projectName,
  startDate,
  endDate,
  budget,
  status,
  manager.firstName as managerFirstName,
  manager.lastName  as managerLastName
} where status != 'Cancelled';

entity SkillsMatrix as select from EmployeeSkills {
  employee.firstName as firstName,
  employee.lastName  as lastName,
  employee.jobTitle  as jobTitle,
  skill.skillName    as skillName,
  skill.category     as skillCategory,
  proficiency,
  yearsOfExperience
};