using { com.hr as hr } from '../db/schema';

service HRService @(path: '/hr') {

  @cds.redirection.target
  entity Employees      as projection on hr.Employees;

  entity Departments    as projection on hr.Departments;

  @cds.redirection.target
  entity Projects       as projection on hr.Projects;

  @cds.redirection.target
  entity Skills         as projection on hr.Skills;

  entity Assignments    as projection on hr.Assignments;

  @cds.redirection.target
  entity EmployeeSkills as projection on hr.EmployeeSkills;

  @readonly entity TeamOverview      as projection on hr.TeamOverview;
  @readonly entity ProjectDashboard  as projection on hr.ProjectDashboard;
  @readonly entity SkillsMatrix      as projection on hr.SkillsMatrix;
}