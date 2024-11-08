# Imagen base de Java (OpenJDK 17 sobre Alpine)
FROM openjdk:17-jdk-alpine

# Directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar el archivo JAR compilado en el directorio target al contenedor
COPY target/Telebot.GPT-0.0.1-SNAPSHOT.jar /app/tu-app.jar

# Comando para ejecutar la aplicación
ENTRYPOINT ["java", "-jar", "/app/tu-app.jar"]

# Exponer el puerto que la aplicación va a utilizar
EXPOSE 8080
