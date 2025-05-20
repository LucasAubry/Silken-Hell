all:
	rm -rf game.love game
	zip -r game.zip *
	mv game.zip game.love
	echo Silken-Hell | npx love.js game.love game -c
	cp index.html game/
	python3 -m http.server --directory game &
	open http://localhost:8000
	trap 'pkill Python; echo hayanne le goat' EXIT; \
	while pgrep -q Python; do sleep 2; done
