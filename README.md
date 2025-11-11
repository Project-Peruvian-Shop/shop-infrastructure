# Entorno AWS con Terraform para Testing

Este proyecto utiliza Terraform para crear y gestionar una infraestructura en AWS destinada a pruebas. La infraestructura incluye una instancia EC2 y grupos de seguridad.

## Requisitos Previos

- Tener las credenciales (`secret.tfvars` y `terraform-deployer_accessKeys.csv`).
- Tener aws-cli instalado.
- Tener node.js con angular-cli instalado.
- Tener Microsoft OpenJDK 21 instalado.
- Tener terraform instalado.

## Variables sensibles

El archivo `secret.tfvars` contiene credenciales y claves secretas necesarias para desplegar la infraestructura y la app.  
⚠️ Mantener fuera del control de versiones.

El archivo `terraform-deployer_accessKeys.csv` contiene las claves de acceso de un usuario IAM con permisos para crear y gestionar recursos en AWS.  
⚠️ Mantener fuera del control de versiones.

## Estructura del Proyecto

- `main.tf`: Define los recursos principales de AWS.
- `secret.tfvars`: Variables específicas para el entorno de desarrollo, ejemplo en `secret.tfvars.example`.
- `terraform-deployer_accessKeys.csv`: Claves de acceso del usuario IAM.
- `scripts/`: Scripts para configurar y desplegar la aplicación.
  - `setup.sh`: Script para tener las variables de entorno de java en windows.
  - `start_backend.sh`: Script para iniciar el backend en la instancia EC2.
  - `frontend.sh`: Script para desplegar el frontend (Angular).
  - `backend.sh`: Script para desplegar el backend (Spring Boot).
- `README.md`: Documentación del proyecto.
- `.gitignore`: Archivos y directorios a ignorar en el control de versiones.
- `.terraform.lock.hcl`: Archivo para gestionar las dependencias de los proveedores.

## Configuración y Despliegue

1. Clona este repositorio en tu máquina local.

2. Copiar archivos `secret.tfvars` y `terraform-deployer_accessKeys.csv` en la raíz del proyecto (cambiar `os_type` si es ubuntu o mac).

3. Ejecutar `aws configure` para configurar con las credenciales de `terraform-deployer_accessKeys.csv`:

   ```bash
   accessKeyId [****************ABCD]: your_access_key_id
   secretAccessKey [****************XYZ]: your_secret_access_key
   default region name [None]: us-east-1
   default output format [None]: json
   ```

4. Dar permisos de ejecución a los scripts:

   En macOS/Linux/Git Bash:

   ```bash
   chmod +x scripts/setup.sh scripts/start_backend.sh scripts/frontend.sh scripts/backend.sh
   ```

5. Ejecutar archivo `setup.sh` en git bash o terminal (Git Bash)

   ```bash
   source scripts/setup.sh
   ```

6. Inicializa Terraform en el directorio del proyecto:

   ```bash
   terraform init
   ```

7. Aplica la configuración para crear la infraestructura:

   ```bash
   terraform apply -var-file="secret.tfvars" -auto-approve
   ```

   Guardar las IPs que se muestran en la salida del comando, por ejemplo:

   ```bash
   mysql_ip = "3.85.243.167"
   nginx_ip = "100.27.199.67"
   springboot_ip = "54.242.0.0"
   ```

8. Ejecutar `start_backend.sh` para iniciar el backend en la instancia EC2:

   En Windows (Git Bash):

   ```bash
   bash scripts/start_backend.sh $springboot_ip ~/.ssh/id_rsa
   ```

   En macOS/Linux:

   ```bash
   ./scripts/start_backend.sh $springboot_ip ~/.ssh/id_rsa
   ```

9. Para destruir la infraestructura cuando ya no la necesites (importante para evitar costos innecesarios):

```bash
terraform destroy -var-file="secret.tfvars" -auto-approve
```

10. Para conectarse al entorno de prueba acceder a `http://<nginx_ip>` en el navegador web.

11. Para volver a desplegar la infraestructura, repetir desde el paso 7.

## Conectarse a la Instancia

Utiliza SSH para conectarte a la instancia EC2. La dirección IP pública se encuentra en la salida del comando `terraform apply`.

En windows:

```
ssh -i C:\Users\<tu_usuario>\.ssh\id_rsa ubuntu@<ip_publica_de_tu_instancia>
```

En macOS/Linux:

```bash
ssh -i ~/.ssh/id_rsa ubuntu@<ip_publica_de_tu_instancia>
```

## Leer logs de user_data

Para revisar los logs generados durante la ejecución del script `user_data`, puedes consultar el archivo de log en la instancia EC2:

```bash
cat /var/log/cloud-init-output.log
tail -n 50 /var/log/cloud-init-output.log
```

## Verificar si el backend está corriendo

Puedes verificar si el backend de tu aplicación está corriendo correctamente accediendo a la URL pública de la instancia EC2 en el puerto 8080. Por ejemplo:

```
ps aux | grep java
```

Salida:

```
ubuntu      7213  7.5 21.8 3174452 426680 ?      Sl   14:20   1:00 java -jar target/hammar-api-0.0.1-SNAPSHOT.jar
```
