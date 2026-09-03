# DesignThinkingProject
## Integrantes
* Natalia Carpintero - @Carpinteron
* Andrés Carrero - @AndresCarrero00
* Paula Núñez - @pzarante
* Andrés Serrano - @serranoaf23
---
# Enunciado
Mobile Development Project | 2026-30

Innovation Hub – Collaborative University Projects

**Team Size:** 4 students per group

## Project Overview
Universities constantly encourage interdisciplinary collaboration, but students often struggle to find teammates from different programs who complement their skills.

The objective of this project is to develop a Flutter mobile application that enables members of the university community to propose ideas, recruit collaborators, build multidisciplinary teams, document project progress, receive peer feedback, and showcase completed projects.

The application should encourage collaboration, innovation, and continuous improvement throughout the lifecycle of a project.

The application supports the complete lifecycle of a collaborative university project. A student begins by publishing an idea describing the problem to solve and the skills required. Other students can discover the proposal, apply to join the team, and collaborate on its development. Throughout the project, the team shares progress updates, validates decisions through community polls, and publishes prototypes for feedback from other students. Based on this feedback, the team iterates on the solution until the project is completed and showcased on the platform.
## Functional Requirements
### Authentication
- Login using institutional credentials. 

- Student profile. 

- Academic program. 

- Skills/interests. 

- Profile picture. 

- Short biography.
### Projects
Any student can create a project proposal (becoming the project leader), each proposal must include:

- Title 

- Description 

- Problem to solve 

- Current stage 

- Required skills 

- Maximum number of members 

- Project tags 

- Images or attachments 
### Team Formation
Students can browse published ideas a can:

- Apply to join a project 

- Cancel an application 

- Leave a project 

- Follow projects without joining them 

The project leader can

- Accept applications 

- Reject applications 

- Remove members 

- Close recruitment once the team is complete
### Project Workspace
Each project has its own workspace containing

- Team members 

- Timeline 

- Progress updates 

- Gallery 

- Milestones 

- Pending tasks 

- Current status 

Suggested statuses

- Idea 

- Team Formation 

- Research 

- Prototype 

- Testing 

- Finished
### Progress Updates
Teams should periodically publish updates, each update includes

- Title 

- Description 

- Images 

- Videos (optional) 

- Date 

- Current completion percentage 

Updates should appear in a project timeline.
### Idea Validation
Students can create polls to validate ideas or gather opinions from the university community.

Each poll must include:

- Title

- Description

- One or more questions

- Closing date

- Target audience (optional)

Other students can:

- Participate in active polls

- View poll results after voting (or after the poll closes)

- Submit optional comments to justify their responses

Polls should be associated with a specific project and remain accessible as part of the project's history.
### Prototype Showcase
Projects in the Prototype stage become visible to the university community.

Students can

- View prototypes 

- Leave comments 

- Give constructive feedback 

- Vote using reactions (optional) 

The project team can reply to the comments.
### Feedback
Students can provide feedback regarding

- Usability 

- Innovation 

- Visual Design 

- Technical Feasibility 

Feedback should remain visible to all users.
### Search
Users can search projects by

- Category 

- Academic program 

- Skills needed 

- Keywords 

- Project status
### Notifications
Users receive notifications when

- Their application is accepted 

- Someone applies to their project 

- Someone comments on their project 

- Someone replies to a comment 

- A followed project publishes an update 

## Non-Functional Requirements
The application must

- Support offline caching for recently viewed projects. 

- Follow Clean Architecture principles. 

- Use GetX for dependency injection, routing, and state management. 

- Use Roble as authentication and backend services. 

- Provide responsive interfaces. 

- Include proper error handling. 

- Follow accessibility best practices. 

- Be fully documented.



