## Code Challenge Generator

- This project is for personal use to generate code challenges for candidates I interview.
- It sets up a project in the candidate's own GitHub repository 
  - making it ready for them to commit and push their solution.

### How It Works
- Create a Public GitHub Repository:
  - Candidates need to create a public GitHub repository where they will push their solution.
- Enter Details:
 - Candidates enter:
  - their GitHub repository URL 
  - the 6-digit verification code (TOTP) provided during the interview.

### Download Challenge:
The system:
- clones the template repository
- configures it
- generates a tar.gz file for the candidate to download.

### Extract and Push:
Candidates extract the contents of the tar.gz file and push them to their GitHub repository.

## Running the Project

- Ensure you have Docker and Docker Compose set up on your system.
- To run this project, simply execute the run.sh file in the project root.
    - `./run.sh`
