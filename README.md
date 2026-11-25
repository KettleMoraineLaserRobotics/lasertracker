![Laser Tracker](https://raw.githubusercontent.com/Raktbastr/lasertracker/refs/heads/main/assets/images/tracker_logo-horizontal.png)

# Laser Tracker
A multiplatform application allowing FRC teams to track the statuses of thier members while at competitions. Developed by Team 2077 Laser Robotics.
### AI Use in this project was in accordance with the Laser Robotics bylaws
*"8.3, The use of primarily AI generated content in published team materials such as the Impact Essay, Safety Animation, or Robot code is prohibited. This does not prohibit team members from using AI to assist in their duties however."*

## What Does It Do?
Laser Tracker allows teams to easily track the locations, roles, and jobs of thier members at competitions. 

The app tracks the following about each member
* Location (stands, cafeteria, pit, juding room, etc...)
* Job (drive team, impact team, pit crew, etc...)
* Role (coach, mentor, student)

Laser Tracker can also function as a pit display on large screens or tablets. In this view it displays your team's next and upcoming matches, drive team members, and the event stream. 

## How Do I Use It?
Laser Tracker can be accessed from https://lasertracker.laserrobotics.org or installed as an APK on android devices.

At the start of an event, a team member (preferably an adult) creates a group for thier team and becomes an admin of it. Once created, the group code can be shared to other members who can then use it to create an account and join the group. Accounts are group specific and can have thier pin, job, location, or role changed by the admins of the assoicated group.

As the event goes on members update their location and job to reflect where they are and what they are doing. Custom locations and jobs can also be set.

A group's event can be changed if needed, but is only reccomended in circumstances such as Worlds where the event key and "event" changes depending on if you make it to Einsteins, while still being the same event in actuality. Doing this makes sure that the displayed schedule and streams are updated while keeping a connected history of the group at the event.

## How does it work, technically?
Laser Tracker is built with Flutter. This allows the project to be ran on many different platforms such as the web and Android, both of which Laser Tracker is configured for.

The backend server ([Laser Tracker Server](https://github.com/Raktbastr/lasertracker_server)) manages the database, event data syncing, and websocket connections. It does NOT host the app itself.

Laser Robotics hosts an instance of Laser Tracker Server at https://api.lasertracker.laserrobotics.org, which serves as the default in the app. If you prefer, you are encouraged to go and run your own instance of the server or client for your team. You are able to easily change the server URL from the login screen of the app. If you host a custom version of the server it is NOT necesscary to host the web app as well. All versions of the app including our own host of it (https://lasertracker.laserrobotics.org) can be configured to use a different server url. 

## Planned features
* Light theme, team theme, and system color pallete
* Event changing
* Improved logging

## Build/Hosting Instructions
### Laser Tracker
1. Make sure you have the Flutter SDK properly installed + Android tools if needed.
2. In the project root run `flutter pub get` to install any dependencies.
3. Run `flutter build <platform>` where platform is either `web` or `apk`
4. What to do with your build files:
    * Web: Host a webserver pointing to index.html.
    * apk: Install the apk

### Laser Tracker Server (Without Docker)
1. Run installation script (link here when I get to it)

### Laser Tracker Server (With Docker)
idk tbh, ill figure it out before release lol
