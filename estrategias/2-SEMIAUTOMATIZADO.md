# Proceso semi-automatizado de despliegue

Aunque podemos hacer nuestros despliegues, tanto iniciales como de versiones, de forma manual obteniendo un funcionamiento correcto, puede convertirse en una tarea tediosa. Por cada cambio que necesitemos desplegar debemos entrar a la máquina de destino y ejecutar ciertas tareas de forma mecanizada para realizar el mismo proceso siempre.  
Esto sumado a la posibilidad de ruptura o descuido que puede producirse durante el despliegue, lo convierte en un procediemiento de riesgo que deberíamos intentar evitar para aplicaciones que van a tener un ciclo de vida contínuo.

Para evitar tener que pasar por el procedimiento manual podemos plantear una estrategia basada en scripts que hagan todas esas tareas por nosotros. Cada paso que debemos dar en el proceso manual puede quedar reflejado en un script que se encargue de ralizarlo por nosotros, obteniendo los siguientes beneficios:

- No tendremos que realizar todas las tareas nosotros mismos en cada ocasión.
- Reducción de riesgos. Al ser un proceso automático evitamos que haya errores humanos durante el desarrollo del despligue.
- Podemos añadir o eliminar pasos en nuestro proceso con un único esfuerzo.
- Ejecutamos todas las acciones con un solo comando.

## Shell script

Esta estrategia se basa en la ejecución de un comando. Para ello plantearemos el uso de un **shell script** que nos permita aglutinar los pasos necesarios en nuestro despliegue. En nuestro caso, usaremos el [script de ejemplo](../automation-script.sh).  
Este script deberá ser ejecutado desde nuestra máquina local:

```bash
ssh <AUTHORIZED_USER>@<SERVER_IP> "cd <PROJECT_FOLDER> && sh automation-script.sh"
```

Para poder ejecutar el script es necesario contar con un usuario SSH autorizado en la máquina, tal y como se detalla en el [proceso manual](./1-MANUAL.md##conexión-con-el-server)

El script deberá ser un archivo más del proyecto. Se recomienda usar una carpeta `deploy` o similar que contenga todos los archivos necesarios para realizar los despliegues, que serán versionados junto con el resto del proyecto.  
Es importante **no guardar claves ni valores sensibles** en estos scripts.

La idea es contar con este tipo de archivos para despliegue en entornos de **producción**, aunque es posible hacer uso de esta técnica en otro tipo de entornos para _testing_.

## Comandos

El script no deja de ser una serie de comandos secuenciales que se ejecutan en serie. Cada comando es ejecutado de forma independiente.  
Podemos entender cada sentencia como instrucciones que escribiríamos de forma manual, pudiendo además recibir parámetros al ejecutar el script.

```bash
#! /bin/bash

# Actualizar sistema
sudo apt update
# Instalar una dependencia
sudo apt install git
...
```

### Inconvenientes

Este sistema, aunque cómodo y reutilizable, cuenta con ciertos riesgos que debemos tener presentes:

- No tenemos control sobre el flujo. Una vez lanzado el script no se detendrá hasta completarse o fallar.
- En caso de error la ejecución continuará, pudiendo generar escenarios incompletos donde la aplicación no es estable.
- Cualquier usuario puede ejecutar este script, teniendo acceso a las variables de entorno involucradas, lo que hace algo más inseguro el sistema.

Para paliar alguno de los inconvenientes mencionados, en cuanto a control de ejecución, se puede plantear una estrategia añadida, como hacer comprobaciones de los pasos al final para detener los servicios creados en caso de error en alguna parte del proceso.
