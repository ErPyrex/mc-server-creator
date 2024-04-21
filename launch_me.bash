#!/bin/bash

# Funciones

install_ngrok ()
{
  curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && sudo apt update && sudo apt install ngrok
  return 0
}

echo "Actualicemos la lista de paquetes primero"
sudo apt update &>/dev/null && echo "Actualizada con exito la lista de paquetes" || echo "¡Error al actualizar la lista de paquetes!" 
echo "instalaremos java 8 y ngrok"
sudo apt install openjdk-8-jre-headless -y &>/dev/null && echo "Java 8 Instalado" || echo "Error al instalar Java 8"
install_ngrok &>/dev/null && echo "Ngrok instalado con exito" || echo "Ngrok no instalado"
echo "Configurando ngrok"
echo "Obten tu authtoken de ngrok en https://dashboard.ngrok.com/auth"
read -p "Por favor pega tu authtoken de ngrok: " authtoken_key
ngrok config add-authtoken $authtoken_key &>/dev/null && echo "ngrok configurado correctamente" || echo "configuracion de ngrok ha fallado"
read -p "¿Tienes otras versiones de java? (Y / N): " java_ver
if [[ $java_ver == *y* ]]; then
  echo "Por favor selecciona java 8"
  sudo update-alternatives --config java
else
  echo "Continuemos" ...
fi
read -p "¿El server sera forge o vanilla? (F / V): " server_type
if [[ $server_type == *f* ]]; then
  jar_name="forger_installer.jar"
elif [[ $server_type == *v* ]]; then
  jar_name="vanilla_installer.jar"
fi
if [[ $server_type == *f*  ]]; then
  echo "Descargando archivos de server Forge"
  wget -O $jar_name https://maven.minecraftforge.net/net/minecraftforge/forge/1.12.2-14.23.5.2859/forge-1.12.2-14.23.5.2859-installer.jar &>/dev/null && echo "Descarga completa" || echo "Descarga fallida"
  java -jar $jar_name --installServer &>/dev/null && echo "Servidor forge instalado con exito" || echo "Instalacion fallida"
  rm -rf $jar_name
elif [[ $server_type == *v* ]]; then
  echo "Descargando archivos de server Vanilla"
  wget -O $jar_name https://piston-data.mojang.com/v1/objects/886945bfb2b978778c3a0288fd7fab09d315b25f/server.jar &>/dev/null && echo "Descarga completa" || echo "Descarga Fallida"
fi
