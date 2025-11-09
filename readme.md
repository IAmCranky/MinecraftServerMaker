- Make dedicated folder
- Download server jar
- Install required Java Edition
- Run command to start server for the first time

```sh
java -Xmx1024M -Xms1024M -jar minecraft_server.1.21.10.jar nogui
```

- Agree to EULA
- Set Server properties
- Start server
- Create regular backups
- Adding Mods/Modpacks

# Directory.bat
- Get's the file path that the user wants their server files installed on
- Creates the folder if it doesn't exist

#jdk.bat
- Takes the Open JDk version number as an integer 
- Downloads the OpenJDK msi
- Installs the OpenJDK version

Passing arguments to bat:

set FORGE_VERSION=%~1
set SERVER_DIR=%~2
set INSTALLER_JAR=forge-%FORGE_VERSION%-installer.jar

call your_script.bat "1.20.1-47.2.0" "D:\my-minecraft-server"