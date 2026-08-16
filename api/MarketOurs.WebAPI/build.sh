git pull
sudo docker stop mo_webapi
sudo docker rm mo_webapi
sudo docker build -t mo_webapi .
if [ ! -f ./prod.env ]; then
  echo "错误：未找到 ./prod.env，请先创建该文件再运行。"
  exit 1
fi
sudo docker run -d   --name mo_webapi   -p 38080:8080   --env-file ./prod.env   mo_webapi:latest