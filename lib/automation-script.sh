#! /bin/bash

# Retornamos el repositorio al estado del último commit
git reset --hard

# Traemos las novedades de la rama de producción
git pull origin master
echo "--> Repositorio actualizado"

# Actualizar dependencias del proyecto
npm install --production

# Crear archivos compilados (proyectos React, Babel....)
npm run build
echo "--> Estáticos creados"

# Sobreescritura de servidor Nginx
sudo cp -rf ./default /etc/nginx/sites-available

# Reinicio de servidor Nginx
sudo systemctl restart nginx
echo "--> Servidor Nginx actualizado"

# Sobreescritura de variables de entorno para servicio de procesos Node.js (proyectos back o API)
sudo cp -rf ./template.env /etc/systemd/system/template.env

# Sobreescritura del servicio para proceso en Node.js (proyectos back o API)
sudo cp -rf ./template.service /etc/systemd/system/template.service

# Reinicio de servicio del proceso Node.js (proyectos back o API)
sudo systemctl restart template
echo "--> Servicio API corriendo"