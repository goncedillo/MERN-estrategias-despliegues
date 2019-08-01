# Proceso manual de despliegue

1. [Dependencias](#dependencias)
2. [Conexión con el servidor](#conexión-con-el-server)
3. [Despliegue del código](#despliegue-del-código)
4. [Ejecución como servicio](#ejecución-como-servicio)
5. [Servidor web](#servidor-web)

## Dependencias

Para el proceso de despliegue manual deberemos contar con los siguientes elementos:

- Código de nuestra/s en repositiorios GIT
- Un servidor para el despliegue (puede ser virtual como Vagrant en fase de pruebas) con las dependencias necesarias instaladas:
  - Node.js - [instalación en Ubuntu](https://www.digitalocean.com/community/tutorials/como-instalar-node-js-en-ubuntu-16-04-es)
  - MongoDB - [instalación en Ubuntu](https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/)
  - GIT - [instalación en Ubuntu](https://www.digitalocean.com/community/tutorials/how-to-install-git-on-ubuntu-18-04)
  - Nginx - [instalación en Ubuntu](https://www.digitalocean.com/community/tutorials/como-instalar-nginx-en-ubuntu-18-04-es)
- Cliente SSH para conectar a nuestro servidor
- Aplicación creada y configurada en Gitlab para Oauth en nuestra app

## Conexión con el server

Como primer paso deberemos conectarnos por SSH a nuestro servidor. En caso de trabajar en Vagrant será mediante comando de conexión `vagrant ssh`.

Para el resto de casos deberemos contar con una clave de SSH en nuestro sistema. Si no contamos con ninguna podemos crear una con el comando:

```bash
ssh-keygen
```

Esto nos hará una serie de preguntas, como ruta donde crear el par de claves o la frase para cifrarlas (por comodida podemos dejarla vacía) generando al final un output similar a este:

```
The key's randomart image is:
+---[RSA 2048]----+
|     .+.++ooo E*=|
|     = o.o.*...+=|
|      B o.++.  oB|
|     o o+oo . .oB|
|     . +So   . +.|
|    . +.      . .|
|     ...         |
|    .  .         |
|     ..          |
+----[SHA256]-----+
```

Con esta clave solo tenemos que añadir su parte pública `clave.pub` dentro del archivo `/home/usuariodelserver/.ssh/authorized_keys` y ya podemos conectarnos desde nuestra máquina pasándole nuestra clave privada:

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub {username}@{remotePublicIPAddress}
```

Muchos servicios cloud proveen forma de añadir estas claves SSH desde el propio panel de usuario, facilitando la integración de este sistema.

## Despliegue del código

Existen muchas opciones para llevar el código necesario al servidor, como enviarlo mediante `ftp` o `scp`, pero estos sistemas no ofrecen un control de las versiones que se están desplegando y hacen muy difícl su mantenimiento y actualización.

Git nos ofrece la posibilidad de obtener este control de versiones, además de la posibilidad de desplegar el código necesario en cada momento. Por lo que parece una mejor opción que las anteriores.

Para poder traer nuestros repositorios de código es necesario que el repositorio remoto, donde se centraliza el código, permita la conexión de nuestro servidor para la descarga del proyecto (en caso de repositorios privados).

En este caso necesitaremos reproducir el paso anterior y crear unas claves SSH en el servidor que deberemos añadir como permitidas en el repositorio remoto.
Normalmente todos los servicios de este tipo admiten esta funcionalidad entre las opciones del repositorio.

Una vez que tenemos permisos para obtener las fuentes del repositorio debemos traer el código siempre de la rama **master** que es la que se asocia a entornos de producción. En caso de utilizar el servidor para otro tipo de entorno, deberemos descargar la rama que corresponda.

```bash
git remote add origin http://XXXXXXXXXX

git pull origin master
```

Algunos proyectos (sobretodo orientados a front) requiren pasos extra, como correr comandos de generación de contenido para entornos distributivos:

```
npm run build

gulp build

...
```

## Ejecución como servicio

Con nuestro proyecto ya desplegado ahora necesitamos ejecutarlo.  
Aunque nos podría servir correrlo de forma imperativa (por una llamada nuestra a su ejecutable _node index.js_), no sería la manera más recomendada, ya que podría fallar por cualquier motivo y necesitaríamos reiniciarlo a mano en cada caso.

Podemos pensar en utilizar _demonios_ para lanzar nuestras aplicaciones. En el caso de Node.js existen varios muy buenos como [Nodemon](https://nodemon.io/) o [PM2](http://pm2.keymetrics.io/) que son grandes soluciones, pero más recomendado para trabajar en local o entornos no productivos.  
La razón es que no es buena idea usar como demonio para una tecnología un servicio de la misma tecnología. Existen soluciones más optimizadas y cercanas al sistema.

En nuestro caso trataremos nuestras aplicaciones como un servicio nativo del sistema. En versiones modernas (>16.04) de Ubuntu contamos con el demonio `systemd` que nos ofrece una interfaz para manejar y declarar servicios.

##### Creación

El primer paso será declarar nuestro servicio en el sistema. Para ello deberemos crear un archivo como el [servicio de ejemplo](../lib/template.service) en la ruta `/lib/systemd/system/<NOMBRE_SERVICIO>.service`

En este paso ya tendremos un servicio con el nombre elegido para correr nuestra aplicación.

##### Variables

De forma adicional, podemos necesitar (como en nuestro caso) ciertas variables de entorno para ejecutar. En ese caso deberemos crear un archivo de variables como el propuesto en el [ejemplo de variables](../lib/template.env) y declararlo con el nodo `EnvironmentFile`.  
Las variables de entorno deberían guardarse en la ruta `/etc/systemd/system/<NOMBRE_ARCHIVO>.env`.

##### Ejecución

Con todo listo debemos reiniciar el demonio:

```bash
sudo systemctl daemon-reload
```

Tras lo que ya podremos ejecutar nuestro servicio:

```bash
sudo systemctl start NOMBRE_SERVICIO.service
```

Con esto ya tendremos nuestras aplicaciones corriendo como servicio, pudiendo marcar una política de reinicios basados en error, o inical cuando tengamos red, etc.

## Servidor web

Una vez que tenemos nuestro proyecto desplegado y corriendo como un servicio necesitamos una manera de acceder a él. Siempre podemos acceder a la IP del servidor donde estamos desplegados. Pero las IP cambian con el tiempo y no son la manera más adecuada de acceder a nuestros proyectos, ya que siempre necesitaríamos conocer el puerto donde corre la aplicación, que nunca podrá ser el 80 como sería normalmente en un proyecto web.

Para poder servir nuestro proyecto necesitamos montar un servidor web, que se encargue de redireccionar las peticiones a nuestro proyecto y a su vez que haga de proxy reverso para mapear la peticón de entrada a un puerto del sistema con los parámetros que traía.

En este caso elegimos [Nginx](https://www.nginx.com/) como servidor que además ofrece proxy reverso.  
Para instalarlo necesitamos ejecutar el siguiente comando en nuestro sistema Ubuntu:

```bash
sudo apt install nginx
```

Una vez instalado debemos establecer la configuración de nuestros servidores (front y back). Para ello cambiaremos el archivo `/etc/nginx/sites-available/default` que contiene la configuración por defecto.  
Deberemos sustituir este archivo por el [nuestro](../lib/default):

##### Front

En él podemos observar que hemos configurado un primer servidor que escuchará en puerto 80 atendiendo peticiones para un **server_name** concreto.  
Estas peticiones serán resueltas de forma estática sirviendo archivos que en la carpeta marcada como **root**, intentando servir como **index** ciertos tipos de archivo, por orden de importancia.

Acabamos decalarando una ruta `/` que será la ruta base de nuestro servidor donde intentará servir las rutas _html_ necesarias si las encuentra o maneja nuestra SPA.  
En caso de no encontrarla, generará una redirección 404.

##### Back

Por otro lado, declaramos un servidor para nuestro back. En nuestro caso usamos Node.js y Express como servidor, con lo que simplemente necesitaremos redirigir las peticiones al puerto designado en nuestro proyecto.

Este proceso se lleva a cabo usando un `proxy_pass` que redirige el tráfico a un `upstream` uqe declaramos apuntando a nuestro propio servidor y al puerto necesario.  
Acompañando la redirección, mapeamos la IP de la petición, así como otros datos necesarios para su posible monitorización o interacción.

##### Puesta en marcha

Una vez completa la configuración de nuestro servidor, deberemos reiniciar (o iniciar si estaba detenido) el servicio de Nginx:

```bash
sudo systemctl start nginx
```

Si no hemos cometido ningún error en la configuración de nuestro servidor no deberíamos obtener respuesta. Podemos, además, comprobar el estado de nuestro servicio usando el siguiente comando:

```bash
sudo systemctl status nginx
```

##### Hosts

En caso de estar trabajando en un servidor montado en un entorno local (o no contar aún con un dominio para el proyecto) podemos hacer un mapeo de _hosts_ en nuestra máquina, para que las peticiones que se hagan al server indicado se mapeen a otro destino elegido por nosotros.

Para ello deberemos editar (con permisos de admin) el archivo **hosts** de nuestro sistema. En caso de Linux o Mac podremos encontrarlo en la ruta `/etc/hosts`. Para Windows tendremos que buscarlo en `c:\Windows\System32\Drivers\etc\hosts`.

Deberemos añadir una línea al archivo asociando una IP a un nombre dominio:

```txt
127.0.0.1   eldominioamapear.loquequiera
```

De esta forma, cada petición dentro de mi máquina a ese dominio será mapeada a la IP asignada, que puede ser mi propia máquina, una IP de una máquina virtual u otro servidor externo.
