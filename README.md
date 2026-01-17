# claude code + ansible skills project

## repository

**https://github.com/sigridjineth/hello-ansible**

## what is this

this repository contains custom skills for claude code that help you work with ansible more effectively. when you place skill files in the `.claude/skills/` directory of your project, claude code reads them and uses that knowledge to provide better assistance when you're working on ansible-related tasks.

the idea is simple: instead of explaining ansible best practices every time you ask for help, you encode that knowledge into skill files once, and claude code applies it automatically. this means more consistent outputs, fewer mistakes, and playbooks that follow established patterns from the start.

## what skills are included

the repository includes four main skill files, each covering a different aspect of ansible development.

the first skill is `ansible-playbook.md`, which covers playbook authoring best practices. it explains how to structure your project directories, including where to put inventory files, group variables, host variables, and roles. it describes naming conventions for tasks and variables, how to use tags effectively, and when to use handlers versus regular tasks. it also covers security topics like using ansible-vault for sensitive data, and testing strategies including check mode, diff mode, and molecule for role testing.

the second skill is `ansible-modules.md`, which serves as a quick reference for commonly used ansible modules. instead of looking up documentation every time, claude code can reference this skill to use the right module for each task. it covers file operations like creating directories, copying files, and modifying configuration files. it covers package management across different distributions, service management with systemd, user and group management, downloading files from the web, making api calls, and working with archives.

the third skill is `shell-to-ansible.md`, which helps convert legacy shell scripts into proper ansible playbooks. this is probably the most practically useful skill for teams migrating from manual scripts to infrastructure as code. it provides a mapping table showing which shell command corresponds to which ansible module. for example, `mkdir -p` becomes the file module with `state: directory`, `apt-get install` becomes the apt module, and `systemctl restart` becomes the service module. the skill includes a complete worked example showing a 70-line deployment script being converted into a structured playbook with proper error handling, handlers, and templates.

the fourth skill is `ansible-interactive.md`, which defines a conversational workflow for building ansible projects step by step. this is useful when you're starting from scratch and want claude code to guide you through the process. it breaks down the development into phases: first analyzing your environment and gathering information about your servers, then creating the initial project structure and inventory, testing connectivity, writing a simple playbook, gradually adding features based on your requirements, refactoring into roles when the code gets complex enough, and finally documenting everything properly.

## how to use it

first clone the repository to your local machine. then open the directory with claude code. once you're in the project, you can start asking for ansible-related help in natural language.

for example, you might say "create a playbook that installs nginx and configures it as a reverse proxy". claude code will read the skills and generate a playbook that follows the directory structure conventions, uses appropriate modules instead of shell commands, includes proper error handling, and sets up handlers for service restarts.

another example: you could paste a shell script and ask "convert this to ansible". claude code will use the shell-to-ansible skill to map each command to the appropriate module, extract hardcoded values into variables, add idempotency where the original script lacked it, and structure the result as a proper playbook or role.

you can also take the interactive approach by saying something like "help me set up ansible for my servers step by step". claude code will walk you through the phases defined in the interactive skill, asking about your server inventory, testing connections, and building up the automation gradually.

## why this matters

the combination of claude code and ansible is powerful because it addresses the main pain points of infrastructure automation. writing ansible playbooks requires knowing which modules exist, what parameters they accept, and how to structure everything properly. this knowledge takes time to acquire and is easy to forget. by encoding it into skills, you get consistent, high-quality outputs without having to remember everything yourself.

the shell-to-ansible conversion skill is particularly valuable for teams with legacy automation. most organizations have accumulated shell scripts over the years that work but are fragile, not idempotent, and hard to maintain. converting them to ansible manually is tedious and error-prone. having claude code do the heavy lifting while following a consistent conversion methodology speeds up the migration significantly.

the interactive workflow skill recognizes that infrastructure automation is often an iterative process. you don't always know exactly what you need upfront. being able to develop incrementally, testing each step before moving on, reduces the risk of building something that doesn't work in your specific environment.

## contributing

the repository welcomes contributions. if you find patterns that work well in your ansible projects, consider adding them to the skills. if you notice the skills giving incorrect advice, open an issue or submit a fix. the goal is to make this a community resource that captures collective knowledge about ansible best practices.
