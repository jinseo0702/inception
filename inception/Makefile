CMD = docker compose
UP = up --build -d
DOWN = down --rmi all
RM = rm -rf
LOG = logs
PS = ps
EXEC = exec
SH = sh
MARIADB = db
NGINX = web
WORDPRESS = wordpress
COMPOSEPATH = -f

COMPOSE = /home/inception/srcs/compose.yaml

VOLUME = /home/login/data/wordpressvol \
/home/login/data/dbvol \

SRC = ./srcs/requirements/tool/do \

all :
	@$(SRC)
	@$(CMD) $(COMPOSEPATH) $(COMPOSE) $(UP)

clean :
	@$(CMD) $(COMPOSEPATH) $(COMPOSE) $(DOWN)

fclean :
	@$(CMD) $(COMPOSEPATH) $(COMPOSE) $(DOWN)
	@$(RM) $(VOLUME)

re : 
	@make fclean
	@make all

log-mariadb :
	@$(CMD) $(COMPOSEPATH) $(COMPOSE) $(LOG) $(MARIADB)

log-wordpress :
	@$(CMD) $(COMPOSEPATH) $(COMPOSE) $(LOG) $(WORDPRESS)

log-nginx :
	@$(CMD) $(COMPOSEPATH) $(COMPOSE) $(LOG) $(NGINX)

logf :
	@$(CMD) $(COMPOSEPATH) $(COMPOSE) $(LOG) $(COMPOSEPATH)

exec-mariadb :
	@$(CMD) $(COMPOSEPATH) $(COMPOSE) $(EXEC) $(MARIADB) $(SH)

exec-wordpress :
	@$(CMD) $(COMPOSEPATH) $(COMPOSE) $(EXEC) $(WORDPRESS) $(SH)

exec-nginx :
	@$(CMD) $(COMPOSEPATH) $(COMPOSE) $(EXEC) $(NGINX) $(SH)

ps-all :
	@$(CMD) $(COMPOSEPATH) $(COMPOSE) $(PS)

.PHONY: all clean fclean re log-mariadb log-wordpress log-nginx exec-mariadb exec-wordpress exec-nginx logf
