# Entorno AWS con Terraform para Testing

Este proyecto utiliza Terraform para crear y gestionar una infraestructura en AWS destinada a pruebas. La infraestructura incluye una instancia EC2 y grupos de seguridad.

## Requisitos Previos

- Tener las credenciales (`terraform-deployer_accessKeys.csv`).
- Tener aws-cli instalado.
- Tener Microsoft OpenJDK 21 instalado.
- Tener terraform instalado.

## Variables sensibles

El archivo `terraform-deployer_accessKeys.csv` contiene las claves de acceso de un usuario IAM con permisos para crear y gestionar recursos en AWS.  
⚠️ Mantener fuera del control de versiones.

## Estructura del Proyecto

- `main.tf`: Define los recursos principales de AWS.
- `secret.tfvars`: Variables específicas para el entorno de desarrollo, ejemplo en `secret.tfvars.example`.
- `terraform-deployer_accessKeys.csv`: Claves de acceso del usuario IAM.
- `README.md`: Documentación del proyecto.
- `.gitignore`: Archivos y directorios a ignorar en el control de versiones.
- `.terraform.lock.hcl`: Archivo para gestionar las dependencias de los proveedores.

## Configuración y Despliegue

1. Clona este repositorio en tu máquina local.

2. Copiar archivos `terraform-deployer_accessKeys.csv` en la raíz del proyecto.

3. Ejecutar `aws configure` para configurar con las credenciales de `terraform-deployer_accessKeys.csv`:

   ```bash
   accessKeyId [****************ABCD]: your_access_key_id
   secretAccessKey [****************XYZ]: your_secret_access_key
   default region name [None]: us-east-1
   default output format [None]: json
   ```

4. Inicializa Terraform en el directorio del proyecto:

   ```bash
   terraform init
   ```

5. Aplica la configuración para crear la infraestructura:

   ```bash
   terraform apply -auto-approve
   ```

   Guardar las IPs que se muestran en la salida del comando, por ejemplo:

   ```bash
   springboot_ip = "54.242.0.0"
   ```

6. Para destruir la infraestructura cuando ya no la necesites (importante para evitar costos innecesarios):

```bash
terraform destroy -auto-approve
```

7. Para volver a desplegar la infraestructura, repetir desde el paso 5.

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
docker ps
docker exec -it <container_id> bash
```

```
ps aux | grep java
```

Salida:

```
ubuntu      7213  7.5 21.8 3174452 426680 ?      Sl   14:20   1:00 java -jar target/hammar-api-0.0.1-SNAPSHOT.jar
```
