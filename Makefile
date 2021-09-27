build :
	@echo " ---- BUILD ---- "
	@docker build -t linkis .

start :
	@echo " ---- START ---- "
	@chmod +x startLinkis.sh
	@./startLinkis.sh
stop :
	@echo " ---- STOP ---- "
	@chmod +x stop.sh
	@./stop.sh

connect :
	@echo " ---- MASTER NODE ---- "
	@docker exec -it cluster-master bash

master-ip :
	@echo " ---- MASTER NODE IP ---- "
	@echo "Master node ip : " $(shell docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cluster-master)

run :
	@echo " ---- RUN ---- "
	@chmod +x run.sh
	@./run.sh