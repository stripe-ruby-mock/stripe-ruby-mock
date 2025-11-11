build:
	docker-compose build

run-3.1:
	docker-compose run --rm ruby-3.1

run-3.2:
	docker-compose run --rm ruby-3.2

run-3.3:
	docker-compose run --rm ruby-3.3

run-3.4:
	docker-compose run --rm ruby-3.4

up:
	docker-compose up

down:
	docker-compose down --remove-orphans

clean:
	docker-compose down --rmi all --volumes --remove-orphans