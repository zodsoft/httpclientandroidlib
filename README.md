Purpose
=============
This project was designed to allow you to use newer versions of the Apache HTTP Components in your Android projects. If you try to use a newer JAR from Apache in your project, it overlaps with the one built into the Android SDK (which is out of date, too). This project fixes that by using different package names for everything.

Depedencies
=============
1. Android SDK
2. ant (`sudo apt-get install ant`)
3. subversion (`sudo apt-get install subversion`)

How To Use The Script
=============
1. Open the script in a text editor, and replace `/home/aidan/android-sdk-linux` with the path to the Android SDK on your computer.
2. Open a Terminal.
3. `cd` into the `scripts` directory of this project.
4. Type `./run.sh`
5. Wait for the process to complete; a JAR, Android Library Project, and ZIP file will be generated if the build is successful (the JAR is the easiest to add to your own projects as a reference).

Implementing
=============
One you have referenced the generated JAR or Library Project in your app, you can use all the Apache HTTP Component classes such as `HttpClient`, but instead of importing from `org.apache.http`, you must import from `ch.boye.httpclientandroidlib`.
