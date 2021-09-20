# Introducción

POC: Provisionar IaC con Terraform en AWS a través de CI/CD con Azure DevOps.

Se provisiona una máquina en una subred privada que funciona como servidor web con nginx y una máquina en subred pública que funciona como un bastión dentro de una VPC con sus respectivas subredes. La infraestructura se crea automaticamente desde IaC y el servidor web tiene la configuración automatizada para su creción con un mensaje de `Hola Nubox!`

# Consideraciones: Generales

* Seguir los pasos específicos descritos para su uso. 

* Estos pasos contemplan el uso de recursos en Azure DevOps como SCV y CI/CD: 

* Existen recursos creados manualmente.

* Tener presente que algunos recursos pueden incurrir costos fuera de la la capa gratuita de AWS.

* Eliminé los recursos tan pronto termine la POC. 
 

# Descripción 

## Este proyecto en una POC que provisiona los siguientes recursos en AWS desde IaC usuando Terraform a través de CI/CD en Azure DevOps.

### **Recursos en AWS**  

* Creados manualmente
    - 1 S3 standard bucket
    - 1 Programmatic user
    - 2 Key pairs

* Creados desde IaC
    - 1 VCP
    - 1 Internet Gateway
    - 1 EIP
    - 2 Route tables
    -  EC2 instances (Linux Ubuntu 18.04)
    - 2 Security groups
    - 2 Subnets
        

### **Diagrama de la IaC en AWS** 

**Caso de uso:** Ejecutar un Web app alojada en un servidor dentro de una red privada al cual se accede solo por **ssh** a traves de un Bastión Host alojado en una subnet pública. Estas son instancias EC2 de uso general. La instancia Bastion puede enviar el tráfico de red saliente a Internet, mientras que la instancia Web de la red privada no, ya que acceden a internet a través de una NAT que se aloja en la subred publica.  
 
![AWS Resources](/data/awsresources.jpg)

### **CI/CD en Azure DevOps**
  - 1 Repositorio     
  - 2 Pipelines       
  - 1 Service Connection (AWS for Terraform)

**Caso de uso:** Ejecución de 2 pipelines para crear y destruir IaC. El primer pipeline crea la IaC en AWS desde la rama principal y el segundo pipeline elimina los recursos desde la rama develop. Los pipelines se ejecutan en integración continua tomando como artefacto el repositorio principal y relacionado con cada rama especifica para el prpósito. 

![AWS Resources](/data/pipelines.jpg)

 # Estructura del proyecto 
- `/data` Contiene imágenes del README.md
- `/src` Contiene el código de la IaC 
    - `main.tf`  Archivo principal que contiene todos los recursos a crear
    - `variables.tf` Archivo con las variables de uso común
    - `install_nginx.sh` Script para instalar ngnix en linux
- `azure-pipeline-apply.yml` CI/CD para construir la IaC 
- `azure-pipeline-destroy.yml` CI/CD para eliminar la IaC 
- `.terraform.lock.hcl` Archivo de dependencias de paquetes y verisiones del provedor cada vez que se ejecutar init. [Conocer más aquí](https://www.terraform.io/docs/language/dependency-lock.html)

# Requisitios previos 
## Herramientas  
- Git 
- Credenciales de AWS 
- AWS cli & AWS Toolkit for Azure DevOps
- Terraform 1.0.7v & Terraform para Azure DevOps
- Cuenta en Azure DevOps
- Visual Studio Code (*Opcional*)

## Técnicos 

- AWS User programmatic con permisos en EC2, VPC y S3. 
    - Permisos en EC2 y VPC de lectura, escritura y eliminar. 
    - Permisos para S3 ver [aquí](https://www.terraform.io/docs/language/settings/backends/s3.html)

- Crear un S3 bucket y crear una carpeta para guardar el archivo terraform.tfstate. Importante **habilitar el versionado**. Guardar los nombres para usarlos más adelante en el pipeline. (Uso: Guardar el archivo terraform.tfstate)

- Crear Key pairs en la sección de AWS EC2. (Uso: conectarse a las instancias de EC2)
    
    Para simplificar, crear 2 key pairs `.pem` con los siguientes nombres que ya estan incluidos en el `main.tf`
    -  `bastionhost1.pem `
    -  `webhost1.pem`

    NOTA: También se pueden crear con otros nombres pero se debe tener en cuenta reemplazarlas en el archivo `main.tf` antes de la contrucción.

# Instalaciones

*Siempre es mejor seguir los pasos desde los sitios oficiales para hacer las inatalaciones.*

## Para trabajo desde local en una Máquina Windows 

- [Instalar Chocholate](https://chocolatey.org/install)

- [Instalar Git](http://git-scm.com/download/win)

    - Actualizar la política Windows:
        1. Via Powershell admin ejecutar los siguientes comandos:

            - `set-executionpolicy remotesigned`
            -   `y`  para confirmar
            - `choco install -y git.install -params '"/GitAndUnixToolsOnPath"'`

        2. Reiniciar Powershell y ejecutar los siguientes comandos para cinfigurar Git:

            - `git config --global user.name "Your name"`
            - `git config --global user.email "your@email.com"`

    - [Instalar AWS cli](https://docs.aws.amazon.com/es_es/cli/latest/userguide/cli-chap-install.html)

        - Configurar un perfil de aws local: 
            - `aws configure --profile dev`
            > Introduzca sus credenciales.

    - [Instalar Terraform](https://www.terraform.io/downloads.html)

    -  Instalar VS Code (*Opcional*) [aquí](https://code.visualstudio.com/)

## Para trabajar directo desde Azure DevOps

- Usar/crear una cuenta de Azure DevOps [aquí](https://azure.microsoft.com/es-es/services/devops/)

- Pasos iniciales con Azure DevOps [aquí](https://azure.microsoft.com/es-es/overview/devops-tutorial/#understanding) 

_NOTA: Si usa otras heramientas de SVC y CI/CD queda a su criterio e investigación adaptarlas.

# Construir y probar 

## Usando Azure DevOps 
### Pasos Previos 
Antes de iniciar con la creación de los recursos en necesario instalar las herramientas:
- Terraform para Azure DevOps. Para instalarla seguir el siguiente [enlace](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks).

- AWS Toolkit para Azure DevOps. Para instalarla seguir el siguiente [enlace](https://marketplace.visualstudio.com/items?itemName=AmazonWebServices.aws-vsts-tools).

### Crear Service Connetions (SC)
#### SC AWS para Terraform 
- Crear la conección con el servicio AWS for Terraform. Seguir los pasos descritos en el [enlace](https://help.veracode.com/r/Create_a_Service_Connection_in_Azure_DevOps); y para este caso, seleccionar `AWS para Terraform` como proveedor y agregar las credenciales correspondientes. 

- Una vez creada, seleccionar y copiar el ID que aparece en la url del navegador `https://dev.azure.com/organización/proyecto/_settings/adminservices?resourceId=59a2c16f-ed24-4b0e-b097-81f5586fbbcc`

     "resourceId=**59a2c16f-ed24-4b0e-b097-81f5586fbbcc**"

    Este ID se deberá reemplazar en los archivos de pipelines YAML en todas las tareas que contienen el input: `backendServiceAWS:59a2c16f-ed24-4b0e-b097-81f5586fbbcc`
    
    ejemplo: 
    ![ejemplo](/data/terraformawsconnection.jpg)

#### SC para AWS cli
   - Seguir las indicaciones del paso anterior, y en este caso selccionar solo el que dice `AWS`. Colocar como nombre `AWS_USER` para simplificar ya que se relaciona a partir del nombre en los pipelines. En caso de usar otro nombre, recodar sustituirlo. 

     ejemplo: 
     ![ejemplo](/data/awsconnection.jpg)

### Crear Repositorio
#### Opciones: 

1.  Se puede importar este repositorio desde github en Azure DevOps hacienco clic en "importar repositorio" en la sección de Repos ![](/data/reposicon.jpg), agregando la url del [origen](https://github.com/damitaintelectual/POC_IaC_AWS_Terraform). `(Requiere autenticación con las credenciales de github)`

2. Crear un nuevo repositorio en la sección de **Repos** y dar clic en `clonar usando VS Code` para llevarlo a la máquina local. Se creará una rama principal (`main`). 

    _(La autenticación se hace automática a través de un PAT entre los recursos de Microsoft)_

    2.1 Clonar este repositorio desde la máquina local con git clone y luego copiar los archivos en el repositorio creado en Azure DevOps:
            
        git clone https://github.com/damitaintelectual/POC_IaC_AWS_Terraform

    2.2 Crear una segunda rama llamada `develop` a partir de la `main` cuando ya estén incluidos todos los archivos. 
    
   ***En los casos anteriroes solo es necesario crear una nueva rama a partir de la rama principal `main` con pocos clics o usando el git checkout desde la máquina local*.**
        
### Crear Pipelines

- Dirigirse a la sección de **Pipelines** ![](/data/pipelinesicon.jpg) para crear 2 pipelines; uno para crear la infra y otro para eliminar. 

    -  **Crear pipeline 1**: 
        - Crear nuevo pipeline a partir de Azure Repos Git YAML
        - Seleccionar el repositorio origen
        - Seleccionar la opción de archivo Azure pipeline YAML existente. 
        - Elegir la rama `main` y seleccionar el archivo `azure-pipeline-apply.yml`.
        - Clic en Continuar y luego en Guardar.

    -   **Crear pipeline 2**: 
        - Crear nuevo pipeline a partir de Azure Repos Git YAML
        - Seleccionar el repositorio origen
        - Seleccionar la opción de archivo Azure pipeline YAML existente. 
        - Elegir la rama `develop` y seleccionar el archivo `azure-pipeline-destroy.yml`.
        - Clic en Continuar y luego en Guardar.

        *Es importante saber que cuando se crean los pipelines de esta forma, sus nombres serán a partir del nombre del repositorio de forma incremental, por lo cual habrá que cambiarlos posteriormente a su creación.*

```NOTA: Tenga en cuenta que esta POC se está usando 2 ramas para realizar las dos operaciones de crear y contruir la Iac en CI/CD. Cuando haga cambios en la rama main se ejecutará automaticamente el pipeline 1 que creará los recursos y cuando se hagan cambios en la rama develop se ejecutará automaticamente el pipeline 2 que eliminrá los recursos```

## Ejecutar Pipelines

### Pipeline 1 - Construir recursos 
1. Ejecutar el pipeline 1, `azure-pipeline-apply.yml` para construir los recursos, yendo a la sección de pipelines y hacer clic en **RUN o Ejecutar**. 
2. Al terminar la ejecución del pipeline, revisar el log de la última tarea llamada "`AWS - Public IP from Web Host`" que contiene la IP pública del Web server.
3. Copiar la IP y pegarla en la url del navegador para validar que el servidor este activo. Deberá aparecer el mensaje **Hola Nubox!**

***NOTA:** En el pipeline, hay una tarea de espera de 1 minuto después de la tarea de creación con la finalidad de aguardar a que el servidor web inicie los servicios y se estabilicen las conexiones. Luego se puede validar el fucionamiento correcto.* 

### Pipeline 2 - Eliminar recursos 

1. Ejecutar el pipeline 2, `azure-pipeline-destroy.yml` para eliminar los recursos, yendo a la sección de pipelines y hacer clic en **RUN o Ejecutar**. 
2. Al terminar la ejecución del pipeline, se puede acceder a la consola sw AWS para certificar que los recursos fueron eliminados. 

# Contribuciones

- [AWS](https://docs.aws.amazon.com/es_es/)
- [HashiCorp](https://www.terraform.io/)
- [Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/?view=azure-devops)
- [Visual Studio Code](https://github.com/Microsoft/vscode)